# SOHOpy

<p align="center">
  <img src="assets/sohopy_logo.png" alt="SOHOpy logo" width="220">
</p>

Modern Python tooling for preparing and calibrating SOHO coronagraph data.

SOHOpy is being scaffolded as a usability-first port of the legacy SolarSoft
IDL reduction code. The first target is the SOHO/LASCO reduction pipeline,
especially the path from Level 0.5 FITS files to consistently prepared Level 1
data. The design goal is a Python interface that is easy to call from scripts,
notebooks, and batch jobs while preserving enough provenance to compare against
the original IDL behavior.

## Current Focus

The first implementation phase is LASCO:

- read LASCO FITS products with stable header normalization
- prepare C2 and C3 images with exposure, bias, vignetting, mask, missing-block,
  photometric, statistics, and provenance corrections
- write reproducible Level 1 FITS products with explicit calibration provenance
- replace process-global IDL state and environment-variable coupling with typed
  configuration objects
- keep calibration assets discoverable, cached, and validated before use
- expose explicit unsupported-step errors for distortion, timing, roll,
  sun-center, and fuzzy-fill behavior that still requires external SolarSoft
  dependencies or IDL parity fixtures

The legacy LASCO REDUCE reference archive has been mirrored locally under
`references/legacy/lasco_idl/` for traceability. See
`docs/lasco_porting_plan.md` for the full porting plan, and
`docs/lasco_port_status.md` for the routine-by-routine port status.

## Intended API

```python
from sohopy.lasco import LASCOConfig, ensure_calibration_assets, reduce_level_1

calibration_root = "/path/to/lasco/calib"
ensure_calibration_assets(calibration_root)

config = LASCOConfig(calibration_root=calibration_root)
result = reduce_level_1("level_05_file.fts", config=config)

print(result.image)
print(result.header["BUNIT"])
```

The same calibration manifest is available from the command line:

```bash
sohopy-lasco-calib /path/to/lasco/calib
sohopy-lasco-calib /path/to/lasco/calib --download
sohopy-lasco-l1 level_05_file.fts level_1_file.fts --calibration-root /path/to/lasco/calib
python scripts/run_lasco_synthetic_workflow.py --output-dir runs/lasco_synthetic_workflow
```

Interactive notebooks are available under `notebooks/`:

```bash
python -m pip install -e ".[notebook,viz]"
jupyter lab notebooks
```

Start with `00_synthetic_full_workflow.ipynb`, then use
`01_lasco_calibration_cache.ipynb` and
`02_lasco_data_download_reduce_visualize.ipynb` for real calibration/data
workflows with fill-in controls for time ranges, data selection, and paths.

Polarization products from calibrated `-60/0/+60` triplets:

```python
from sohopy.lasco import combine_polarizer_triplet_files

pol = combine_polarizer_triplet_files("c2_m60.fts", "c2_0.fts", "c2_p60.fts")
tb = pol.tB
pb = pol.pB
```

The first real LASCO pieces are ported now: FITS I/O, header normalization,
C2/C3 photometric factors, calibration asset inspection/download/loading, C2/C3
vignetting and C3 mask/ramp application, missing-block metadata, statistics,
and C3 clear FITS scaling, plus ideal tB/pB polarization products from
calibrated triplets. Legacy distortion correction, time/roll/sun-center
correction, C3 fuzzy missing-block replacement, and exact `DO_POLARIZ` PTF
behavior still need external SolarSoft dependencies or IDL parity fixtures.

## Project Layout

- `src/sohopy/lasco/`: LASCO-facing Python package
- `docs/lasco_porting_plan.md`: implementation plan, dependency map, and known
  legacy hazards
- `references/legacy/lasco_idl/`: downloaded SolarSoft IDL source references
- `tests/`: focused unit tests for utilities and, later, IDL parity fixtures

## Related Work

This project should reuse the practical lessons from
[SECCHIpy](https://github.com/RobertJaro/SECCHIpy): small importable modules,
clear instrument-specific namespaces, and an API that makes common data
preparation operations easy without hiding calibration provenance.
