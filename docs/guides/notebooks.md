# Interactive Notebooks

SOHOpy includes user-friendly Jupyter notebooks for LASCO workflows.

## Install Notebook Support

From the repository root:

```bash
conda activate sohopy
python -m pip install -r requirements.txt
jupyter lab notebooks
```

The canonical dependency metadata lives in `pyproject.toml`. Notebook support is
available through:

```bash
python -m pip install -e ".[notebook,viz]"
```

## Available Notebooks

`notebooks/00_synthetic_full_workflow.ipynb`
: A guaranteed offline workflow. It creates synthetic LASCO-like inputs, runs
  Level 1 processing, creates tB/pB products, and displays PNG previews.

`notebooks/01_lasco_calibration_cache.ipynb`
: A widget-based calibration cache manager. Fill in the calibration directory,
  timeout, overwrite option, and archive URLs, then inspect or download required
  calibration assets.

`notebooks/02_lasco_data_download_reduce_visualize.ipynb`
: A widget-based real-data workflow. Fill in start/end times, detector, optional
  FITS-header filters, download/output directories, and calibration path. Then
  search public data, download selected results, reduce local FITS files, and
  visualize Level 1 products. If a public archive has sparse detector metadata,
  uncheck the detector constraint and let the notebook filter downloaded files
  by FITS headers.

## Recommended Flow

1. Run the synthetic workflow notebook first.
2. Prepare calibration assets with the calibration notebook.
3. Use the real-data notebook with a short time range and small file count.
4. Increase the time range after the search, download, and reduction behavior is
   clear for your local cache and network.

Public archive metadata can vary between providers. The real-data notebook uses
broad SunPy/Fido search constraints first, then applies filter and polarizer
selection to local FITS headers after download.
