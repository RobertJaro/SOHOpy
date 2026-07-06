# ReadTheDocs And Sphinx Plan

SOHOpy documentation is built with Sphinx and MyST Markdown.

## ReadTheDocs Responsibilities

ReadTheDocs should:

- create a clean Python environment;
- install `requirements-docs.txt`;
- run Sphinx with `docs/conf.py`;
- fail the build on warnings;
- publish versioned documentation for releases and `latest`.

The RTD entrypoint is `.readthedocs.yaml`.

## Sphinx Responsibilities

Sphinx should:

- render narrative guides from Markdown;
- generate API reference pages from docstrings;
- optionally link to Python, NumPy, SciPy, Astropy, and SunPy docs via
  intersphinx when `SOHOPY_ENABLE_INTERSPHINX=1`;
- keep routine status and porting plans close to the public docs;
- build locally with the same command RTD uses.

## Documentation Structure

- `guides/`: user-facing workflows.
- `reference/`: process, parity, release, and maintenance plans.
- `api/`: generated Python API reference.
- `notebooks/`: interactive Jupyter workflows linked from the notebook guide and
  shipped in source distributions.
- top-level project status pages: LASCO port status and porting plan.
