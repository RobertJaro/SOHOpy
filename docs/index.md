# SOHOpy

```{image} ../assets/sohopy_logo.png
:alt: SOHOpy logo
:width: 220px
:align: center
```

SOHOpy is a modern Python package for SOHO data preparation, starting with a
careful port of the LASCO SolarSoft/IDL reduction workflow.

The project has three documentation goals:

- provide practical guides for reducing and calibrating LASCO data;
- document parity with the legacy IDL code routine by routine;
- expose a stable Python API reference suitable for package users and
  contributors.

```{toctree}
:maxdepth: 2
:caption: User Guides

guides/installation
guides/current-capabilities
guides/quickstart
guides/full-workflow
guides/notebooks
guides/lasco-level1
guides/calibration-data
guides/polarization
```

```{toctree}
:maxdepth: 2
:caption: Project Reference

reference/readthedocs-plan
reference/content-plan
reference/release-plan
reference/idl-parity
lasco_port_status
lasco_porting_plan
environment
```

```{toctree}
:maxdepth: 2
:caption: API Reference

api/sohopy
api/lasco
```
