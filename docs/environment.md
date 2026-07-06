# Development Environment

<p align="center">
  <img src="../assets/sohopy_logo.png" alt="SOHOpy logo" width="180">
</p>

The current `sohopy` development environment is a clean Conda environment, not
a clone of another project environment.

```bash
conda env remove -n sohopy -y
conda create -n sohopy python=3.12 pip -y
conda activate sohopy
python -m pip install -r requirements.txt
```

`requirements.txt` is intentionally thin. The canonical dependency metadata
lives in `pyproject.toml`; the requirements file installs the local checkout
with the `dev` extra:

```text
-e .[dev]
```

Verified package versions in the rebuilt environment:

- Python 3.12.13
- SunPy 8.0.0
- Astropy 8.0.1
- NumPy 2.5.1
- SciPy 1.18.0
- Matplotlib 3.11.0
- ipywidgets 8.1.8
- JupyterLab 4.6.1
- notebook 7.6.0
- zeep 4.3.3
- drms 0.9.1
- pytest 9.1.1
- ruff 0.15.20
- Sphinx 9.1.0

The rebuilt environment has no broken requirements according to:

```bash
python -m pip check
```

Operational checks:

```bash
python -m pytest
python -m ruff check src tests examples scripts
LC_ALL=C LANG=C python -m sphinx -W -b html docs docs/_build/html
python scripts/run_lasco_synthetic_workflow.py --output-dir runs/lasco_synthetic_workflow
python -m build
python -m twine check dist/*
```
