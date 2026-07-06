# SOHOpy Notebooks

These notebooks are designed for interactive LASCO workflows.

- `00_synthetic_full_workflow.ipynb`: offline end-to-end demo that creates
  synthetic inputs, reduces them, writes tB/pB products, and visualizes outputs.
- `01_lasco_calibration_cache.ipynb`: widget-driven calibration cache inspection
  and download workflow.
- `02_lasco_data_download_reduce_visualize.ipynb`: widget-driven LASCO data
  search/download/reduction/visualization workflow using SunPy.

Install the notebook environment from the repository root:

```bash
conda activate sohopy
python -m pip install -r requirements.txt
jupyter lab notebooks
```

The real-data notebook uses public data services through `sunpy.net`. Network
availability, remote archive metadata, and calibration-file availability can
vary; the synthetic notebook is the guaranteed local smoke test.
