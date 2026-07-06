# Pip Release Plan

SOHOpy should release as a normal source distribution and wheel.

## Release Readiness Checklist

- All tests pass with `python -m pytest`.
- Lint passes with `python -m ruff check src tests examples scripts`.
- Documentation builds with
  `LC_ALL=C LANG=C python -m sphinx -W -b html docs docs/_build/html`.
- Package builds with `python -m build`.
- Artifacts pass `python -m twine check dist/*`.
- `CHANGELOG.md` has a dated release entry.
- `CITATION.cff` version matches `pyproject.toml`.
- ReadTheDocs builds from the release tag.

## Versioning

Use semantic versioning.

- Patch: bug fixes, docs fixes, parity corrections.
- Minor: new instrument workflows, new calibrated products, new public APIs.
- Major: breaking API or data model changes.

## Distribution Files

The project includes:

- `pyproject.toml` for build metadata;
- `MANIFEST.in` for non-package assets/docs;
- `README.md` for PyPI long description;
- `LICENSE` and `CITATION.cff`;
- optional dependency groups for `test`, `lint`, `docs`, `viz`, `notebook`,
  `release`, and `dev`.
- `twine>=6` so modern package metadata emitted by Hatchling is understood.

## Release Commands

```bash
python -m pip install -r requirements.txt
python -m pytest
python -m ruff check src tests examples scripts
LC_ALL=C LANG=C python -m sphinx -W -b html docs docs/_build/html
rm -rf dist build *.egg-info
python -m build
python -m twine check dist/*
```

Publishing should use trusted publishing where possible.
