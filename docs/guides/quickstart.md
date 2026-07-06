# Quickstart

SOHOpy currently focuses on the LASCO Level 1 preparation path.

```python
from sohopy.lasco import LASCOConfig, reduce_level_1

config = LASCOConfig(calibration_root="/path/to/lasco/calib")
result = reduce_level_1(
    "level_05.fts",
    config=config,
    output_path="level_1.fts",
    overwrite=True,
)

print(result.header["BUNIT"])
```

The calibration root should contain the LASCO calibration FITS files used by the
legacy SolarSoft pipeline. You can inspect the local cache with:

```bash
sohopy-lasco-calib /path/to/lasco/calib
```

To populate missing assets from the configured public archive candidates:

```bash
sohopy-lasco-calib /path/to/lasco/calib --download
```

For a self-contained run without external data:

```bash
python examples/lasco_level1_synthetic.py
python examples/lasco_polarization_synthetic.py
python scripts/run_lasco_synthetic_workflow.py --output-dir runs/lasco_synthetic_workflow
```

For an interactive path with fill-in controls, launch:

```bash
jupyter lab notebooks
```

Start with `00_synthetic_full_workflow.ipynb`, then use the calibration-cache
and real-data notebooks when you are ready to work with public archive data.
