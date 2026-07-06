# Installation

SOHOpy is prepared as a standard Python package with dependency metadata in
`pyproject.toml`.

## Development Environment

The current development environment is named `sohopy`:

```bash
conda create -n sohopy python=3.12 pip -y
conda activate sohopy
python -m pip install -r requirements.txt
```

The requirements file is a convenience wrapper around the local development
extra:

```text
-e .[dev]
```

For a runtime-only user environment after release:

```bash
conda create -n sohopy python=3.12 -y
conda activate sohopy
python -m pip install sohopy
```

For an editable install without the full development toolchain:

```bash
python -m pip install -e .
```

Optional groups are available for narrower installs:

```bash
python -m pip install -e ".[test]"
python -m pip install -e ".[docs]"
python -m pip install -e ".[viz]"
python -m pip install -e ".[notebook]"
python -m pip install -e ".[release]"
```

The `dev` extra includes the test, lint, docs, visualization, notebook, and
release tooling used by the repository. The `notebook` extra includes Jupyter
Lab, ipywidgets, and SunPy network dependencies for `sunpy.net.Fido`.

## Documentation Build

```bash
LC_ALL=C LANG=C python -m sphinx -W -b html docs docs/_build/html
```

ReadTheDocs uses `.readthedocs.yaml` and `requirements-docs.txt`.
