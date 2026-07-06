# Current Capabilities

SOHOpy currently focuses on SOHO/LASCO data preparation.

## Stable User Entry Points

Python API
: `LASCOConfig`, `reduce_level_1`, calibration asset helpers,
  `combine_polarizer_triplet_files`, `write_polarization_products`,
  `plot_lasco_image`, `plot_fits_image`, and `plot_polarization_summary`.

Calibration Helpers
: `required_calibration_assets`, `inspect_calibration_assets`,
  `missing_calibration_assets`, and `ensure_calibration_assets`.

Command Line
: `sohopy-lasco-calib` inspects or downloads calibration assets.
  `sohopy-lasco-l1` reduces one Level 0.5-like FITS file to a Level 1 product.

Repository Scripts
: `scripts/download_lasco_calibration.py` mirrors the calibration CLI.
  `scripts/run_lasco_synthetic_workflow.py` runs a deterministic local workflow
  that writes FITS and PNG products.

Notebooks
: `notebooks/00_synthetic_full_workflow.ipynb` is the offline onboarding path.
  `notebooks/01_lasco_calibration_cache.ipynb` manages calibration assets.
  `notebooks/02_lasco_data_download_reduce_visualize.ipynb` searches/downloads
  public LASCO data with SunPy/Fido, reduces local FITS files, and visualizes
  Level 1 products.

## Implemented LASCO Level 1 Pieces

- FITS I/O and header normalization.
- C2/C3 photometric calibration factors.
- C2 vignetting.
- C3 pre/post-interruption vignetting.
- C3 mask and clear-filter ramp.
- Calibration asset inspection, FITS validation, and download cache.
- Missing-block metadata and compact map helpers.
- Level 1 statistics and C3 clear FITS scaling.
- Ideal tB/pB products from calibrated `-60/0/+60` triplets.
- PNG previews for Level 1 FITS images and polarization summaries.

## Explicit Limitations

SOHOpy raises explicit errors rather than silently approximating these steps:

- exact exposure/bias parity from `GET_EXP_FACTOR` and `offset_bias`;
- optical distortion correction from `c2_warp` and `c3_warp`;
- time, roll, and sun-center correction from `adjust_hdr_tcr`;
- C3 fuzzy missing-block replacement;
- exact `DO_POLARIZ` PTF behavior.

These need external SolarSoft routines, calibration tables, or IDL parity
fixtures before they should be enabled as science-parity behavior.

## Recommended Path

1. Install with `python -m pip install -r requirements.txt`.
2. Run the synthetic workflow script or synthetic notebook.
3. Prepare calibration assets with `sohopy-lasco-calib` or the calibration
   notebook.
4. Reduce known local FITS files.
5. Use the real-data notebook for SunPy/Fido archive search and download.
