# LASCO Porting Plan

<p align="center">
  <img src="../assets/sohopy_logo.png" alt="SOHOpy logo" width="180">
</p>

## Scope

The initial port targets the LASCO REDUCE library and prioritizes the Level 0.5
to Level 1 path. The legacy reference scan covered 70 downloaded IDL files,
about 12.4k lines, from the public SolarSoft LASCO REDUCE help archive. The help
index lists 77 routines and 75 unique `.pro` links; five linked files were
stale or unavailable during the mirror.

## Primary User Workflow

The Python API should make the common path simple:

```python
from sohopy.lasco import LASCOConfig, reduce_level_1

config = LASCOConfig(calibration_root="/data/lasco/calib")
result = reduce_level_1("level_05.fts", config=config, output_path="level_1.fts")
```

The command line wrapper should mirror that API for batch use:

```bash
sohopy-lasco-l1 level_05.fts level_1.fts --calibration-root /data/lasco/calib
```

Polarization products are computed from calibrated and coaligned `-60/0/+60`
triplets:

```python
from sohopy.lasco import combine_polarizer_triplet_files

pol = combine_polarizer_triplet_files("m60.fts", "zero.fts", "p60.fts")
tb = pol.tB
pb = pol.pB
```

## Legacy Pipeline Map

Core Level 1 flow from `reduce_level_1.pro`:

1. Read Level 0.5 FITS with `lasco_readfits`.
2. Normalize/repair image shape with `fixwrap` and `reduce_std_size`.
3. Recreate a Level 1 FITS header.
4. Dispatch by detector:
   - C2: `c2_calibrate`, then `c2_warp`, then missing-block masking.
   - C3: `c3_calibrate` with fuzzy missing-block fill, then `c3_warp`, then mask.
5. Correct time, roll, and sun center with `adjust_hdr_tcr`; fall back to
   `get_roll_or_xy` and `get_sun_center`.
6. Write WCS keywords, `RSUN`, `NMISSING`, `MISSLIST`, and `BUNIT=MSB`.
7. Scale C3 clear images to signed integer FITS values unless disabled.
8. Write FITS and optionally update pipeline database tables.

Level 0.5 flow from `reduce_level_05.pro`:

1. Read compressed LEB `.img` products with `read_leb_image`.
2. Compute compression and summing metadata.
3. Repair known flight/software issues such as cal-lamp `lpulse` in `exp3`.
4. Build FITS headers with `make_fits_hdr`.
5. Rectify coordinates and write Level 0.5 products plus browse/database outputs.

## Python Architecture

- `sohopy.lasco.io`: FITS read/write helpers.
- `sohopy.lasco.headers`: canonical FITS header normalization and validation.
- `sohopy.lasco.config`: explicit configuration that replaces IDL common blocks
  and environment variables.
- `sohopy.lasco.calibration`: C2/C3 photometry, exposure, bias, vignetting,
  mask, ramp, and missing-block calibration primitives.
- `sohopy.lasco.level1`: orchestration for Level 0.5 FITS to Level 1 FITS.
- `sohopy.lasco.geometry`: read-port rectification helpers plus explicit
  unsupported-step errors for warp/time/roll routines that need external
  SolarSoft dependencies.
- `sohopy.lasco.missing_blocks`: base-32 block maps and telemetry block
  detection.
- `sohopy.lasco.statistics`: DATAMIN/DATAMAX/DATAPxx and scaling helpers.
- `sohopy.lasco.assets`: calibration discovery, cache population, and FITS
  asset loading.
- Future module: `level05.py` for decompression and raw LEB image support.

## Porting Phases

### Phase 1: Reproducible Skeleton

- Keep the public API small: `LASCOConfig`, `reduce_level_1`, and CLI. Done.
- Add strict header normalization and validation. Started.
- Add calibration asset discovery/cache population with explicit errors for
  missing assets. Done.
- Build unit tests for simple deterministic helpers: base-32 maps, header keys,
  region slicing, image binning, scaling, and statistics. Started.

### Phase 2: C2/C3 Calibration Parity

- Port `c2_calfactor.pro`, `c3_calfactor.pro`, and `c3_calfactor_var.pro`. The
  current C2/C3 calibration factors are ported; the older C3 variant remains as
  a reference only.
- Port exposure and offset handling currently delegated to `GET_EXP_FACTOR` and
  `offset_bias` outside this archive. Python currently supports explicit
  `EXPFAC`/`OFFSET` headers or an injected exposure-correction provider.
- Implement vignetting selection:
  - C2: `c2vig_final.fts`
  - C3: `c3vig_preint_final.fts` before MJD 51000, otherwise
    `c3vig_postint_final.fts`. Done.
- Implement C3 ramp subtraction from `C3ramp.fts` after vignetting correction.
  Done for clear-filter products.
- Preserve polarization product behavior: PB/TI/UP/JY/JZ/Qs/Us/Qt/Jr/Jt skip
  bias and ramp subtraction. Done.

### Phase 3: Missing Blocks and Geometry

- Port `find_miss_blocks.pro`, `mb2str/*`, and `fuzzy/*` into typed NumPy code.
- Replace IDL `COMMON c3_cal_img` mask sharing with returned calibration state.
- Port or source equivalents for `c2_warp`, `c3_warp`, `adjust_hdr_tcr`,
  `get_sun_center`, `get_sec_pixel`, and `get_solar_radius`.
- Add parity fixtures against known IDL outputs before changing algorithms.

### Phase 4: Level 0.5 and Batch Processing

- Port `make_fits_hdr`, `reduce_refcoord`, `reduce_rectify_p1p2`, and
  `reduce_level_05`.
- Treat database writes, browse image generation, and historical pipeline file
  movement as optional integrations rather than core science preparation.
- Provide batch utilities that can process directories without relying on
  process-global environment variables.

## Legacy Issues To Fix During Port

- Global mutable state: IDL common blocks cache calibration arrays and masks.
  Python should use immutable config and explicit calibration state.
- Environment coupling: `$LASCO_DATA`, `$FITS_OUT`, `$REDUCE_LOG`, and database
  paths are hard-coded assumptions. Python should take paths as arguments.
- Stale references: five help-page source links returned 404 and need a full
  SolarSoft checkout check.
- Duplicate polarization check: `Qt` appears twice in both C2 and C3 branches.
- Hidden dependencies: key routines are outside the REDUCE archive
  (`GET_EXP_FACTOR`, `offset_bias`, `c2_warp`, `c3_warp`, `adjust_hdr_tcr`,
  `get_sun_center`, `get_sec_pixel`, `get_solar_radius`, `read_leb_image`).
- Interactive stops: routines such as `fix_time_jumps.pro`,
  `get_missing_pckts.pro`, and `unpack_lz_science.pro` contain active `stop`
  statements that would hang automated processing.
- Date comparisons: some legacy code compares date strings directly. Python
  should parse dates with `astropy.time.Time` or `datetime`.
- FITS mutation side effects: IDL routines sometimes modify input headers in
  place. Python should return updated headers explicitly.
- Scaling ambiguity: Level 1 C3 clear images are clipped/scaled to signed int
  FITS values with `BSCALE`, `BZERO`, and `BLANK`; parity tests are required.
- Error handling: many legacy routines print and return scalar `0`. Python
  should raise typed exceptions with enough context to fix data or config.

## SECCHIpy Lessons To Carry Forward

- Keep instrument-specific namespaces compact and importable.
- Prefer small functions with ordinary Python objects over framework-heavy
  pipelines.
- Make common data preparation easy, but expose provenance and calibration
  choices so science users can audit outputs.

## Immediate Next Steps

1. Run `scripts/idl/run_lasco_parity.sh tests/fixtures/idl/lasco_parity.json`
   in an IDL/SolarSoft LASCO environment and commit the output fixture.
2. Locate the missing hidden dependencies from a full SolarSoft checkout:
   `GET_EXP_FACTOR`, `offset_bias`, `c2_warp`, `c3_warp`, `adjust_hdr_tcr`,
   `get_sun_center`, `get_sec_pixel`, `get_solar_radius`, `read_leb_image`,
   `fixwrap`, and `reduce_std_size`.
3. Add real calibration asset checksums for `c2vig_final.fts`,
   `c3vig_preint_final.fts`, `c3vig_postint_final.fts`, `c3_cl_mask_lvl1.fts`,
   and `C3ramp.fts`.
4. Build one C2 and one C3 Level 0.5 IDL/Python parity fixture before enabling
   optical warp and fuzzy-fill behavior by default.
