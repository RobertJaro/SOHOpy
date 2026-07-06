# Documentation Content Plan

## Primary Guides

Installation
: Environment creation, pip install, editable install, docs build, and expected
  Python versions.

Quickstart
: Minimal LASCO Level 1 reduction and synthetic examples.

Full LASCO Workflow
: Calibration cache preparation, Level 1 processing, visualization, and the
  deterministic synthetic workflow script.

Interactive Notebooks
: Widget-driven synthetic, calibration-cache, and real-data workflows, including
  network caveats for SunPy/Fido archive access.

LASCO Level 1
: Detailed reduction workflow, implemented steps, missing parity steps, output
  headers, and expected calibration assets.

Calibration Data
: Local calibration-root behavior, public download/cache manager, FITS
  provenance policy, and checksum policy.

Polarization
: tB/pB triplet combination, Stokes products, limitations relative to
  `DO_POLARIZ`, and future PTF parity requirements.

IDL Parity
: How to run IDL scripts, where fixtures live, and how parity tests will be
  incorporated.

Release Guide
: Versioning, test gates, docs gates, build artifacts, twine checks, and PyPI
  publishing steps.

## Reference Content

- API pages generated from docstrings.
- Routine-by-routine LASCO port status.
- Legacy SolarSoft dependency inventory.
- Calibration asset inventory and checksums when available.
- Notebook inventory and launch instructions.
- Changelog and citation metadata.

## Content Rules

- Guides should explain workflows and decisions.
- API reference should document signatures and return types.
- Port-status pages should state current limitations plainly.
- Examples should be runnable without external SOHO data unless explicitly marked
  as real-data examples.
