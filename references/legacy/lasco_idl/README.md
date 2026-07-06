# LASCO Legacy IDL Reference

This directory contains a local mirror of the SOHO/LASCO SolarSoft REDUCE IDL
reference used to plan the Python port.

Source index:

- `help_reduce.html` was downloaded from
  `https://soho.nascom.nasa.gov/solarsoft/soho/lasco/idl/reduce/help_reduce.html`
- 75 `.pro` links were discovered in the generated help page
- 70 source files were downloaded successfully

Unavailable or stale links from the help index:

- `las_c3/build_c3_back.pro`
- `las_c3/calib_c3_sqima.pro`
- `las_c3/corr_edges.pro`
- `getidlpid.pro`
- `las_c3/get_c3_bkgd.pro`

These files should be re-checked against a full SolarSoft checkout before porting
the C3-only helper routines.
