# Full LASCO Workflow

This guide shows the complete SOHOpy LASCO path that is available today:
prepare calibration files, run Level 1 processing, create tB/pB products, and
write preview images.

## Calibration Cache

Inspect the local cache:

```bash
sohopy-lasco-calib /data/lasco/calib
```

Download missing required assets:

```bash
sohopy-lasco-calib /data/lasco/calib --download
```

The equivalent repository script is:

```bash
python scripts/download_lasco_calibration.py /data/lasco/calib --download
```

Downloaded files are validated as FITS files before they are accepted into the
cache. Existing files are reused unless `--overwrite` is supplied.

## Level 1 Processing

Run one Level 0.5 FITS input:

```bash
sohopy-lasco-l1 level_05.fts level_1.fts --calibration-root /data/lasco/calib --overwrite
```

The Python API is the same path:

```python
from sohopy.lasco import LASCOConfig, reduce_level_1

result = reduce_level_1(
    "level_05.fts",
    config=LASCOConfig(calibration_root="/data/lasco/calib"),
    output_path="level_1.fts",
    overwrite=True,
)
print(result.header["BUNIT"])
```

## Visualization

Install the optional plotting dependency:

```bash
python -m pip install "sohopy[viz]"
```

Create a FITS preview:

```python
from sohopy.lasco import plot_fits_image

plot_fits_image("level_1.fts", "level_1.png", title="LASCO Level 1")
```

For polarization products, use `plot_polarization_summary` to write a three-panel
tB, pB, and percent-polarization preview.

## Synthetic End-To-End Run

The repository includes a deterministic workflow that does not require external
SOHO data:

```bash
python scripts/run_lasco_synthetic_workflow.py --output-dir runs/lasco_synthetic_workflow
```

It writes:

- synthetic Level 0.5-like C2 FITS input;
- synthetic calibration cache;
- Level 1 FITS output;
- Level 1 PNG preview;
- synthetic polarizer triplet;
- tB/pB FITS products;
- polarization summary PNG.

This workflow is also part of the automated test suite, so the public examples
stay synchronized with the package API.
