# Calibration Data

SOHOpy loads LASCO calibration files from an explicit local directory:

```python
from sohopy.lasco import LASCOConfig

config = LASCOConfig(calibration_root="/path/to/LASCO_DATA/calib")
```

Expected filenames include:

- `c2vig_final.fts`
- `c3vig_preint_final.fts`
- `c3vig_postint_final.fts`
- `c3_cl_mask_lvl1.fts`
- `C3ramp.fts`
- `3m_clcl_all.fts`

The loader raises `CalibrationAssetError` when a required file is missing. The
same manifest is available from Python:

```python
from sohopy.lasco import (
    ensure_calibration_assets,
    inspect_calibration_assets,
    required_calibration_assets,
)

print(required_calibration_assets())
print(inspect_calibration_assets("/path/to/LASCO_DATA/calib"))
ensure_calibration_assets("/path/to/LASCO_DATA/calib")
```

The command-line interface uses the same code:

```bash
sohopy-lasco-calib /path/to/LASCO_DATA/calib
sohopy-lasco-calib /path/to/LASCO_DATA/calib --download
python scripts/download_lasco_calibration.py /path/to/LASCO_DATA/calib --download
```

The downloader stores assets directly in the calibration root, preserving the
legacy `$LASCO_DATA/calib` layout while making the cache explicit. Existing
files are reused unless `--overwrite` is supplied. Downloaded files are opened
with Astropy FITS before they are accepted, which prevents HTML error pages or
partial mirror responses from becoming cached calibration assets.

Level 1 output headers record the calibration filenames that were applied, for
example `C2VIG`, `C3VIG`, `C3RAMP`, and `C3MASK`. Checksums are intentionally
not invented yet; they should be added when authoritative public hashes are
available for the calibration archive.
