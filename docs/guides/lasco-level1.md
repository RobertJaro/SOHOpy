# LASCO Level 1

The Level 1 path is the main porting target for the first release.

## Implemented

- FITS reading and writing
- header normalization
- C2 and C3 photometric calibration factors
- C2 vignetting
- C3 pre/post-interruption vignetting
- C3 mask and clear-filter ramp
- calibration asset inspection/download cache
- missing-block metadata
- Level 1 statistics
- C3 clear FITS scaling

## Still In Progress

- exact exposure/bias parity from `GET_EXP_FACTOR` and `offset_bias`
- optical distortion correction from `c2_warp` and `c3_warp`
- time, roll, and sun-center correction from `adjust_hdr_tcr`
- C3 fuzzy missing-block replacement

The Python API exposes explicit hooks or errors for these missing steps so that
partial products are not silently mislabeled as complete parity products.

## Output Provenance

SOHOpy writes FITS headers with calibration values such as `CALFAC`, `EXPFAC`,
`OFFSET`, `BUNIT`, `NMISSING`, `MISSLIST`, and Level 1 statistics keywords.
Calibration filenames are recorded in FITS-safe keywords such as `C2VIG`,
`C3VIG`, `C3RAMP`, and `C3MASK`.
