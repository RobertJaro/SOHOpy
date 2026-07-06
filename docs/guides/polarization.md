# Polarization Products

SOHOpy can compute ideal tB and pB products from calibrated, coaligned LASCO
`-60/0/+60` polarizer triplets.

```python
from sohopy.lasco import combine_polarizer_triplet_files

pol = combine_polarizer_triplet_files("m60.fts", "zero.fts", "p60.fts")
tb = pol.tB
pb = pol.pB
```

The implementation uses the standard three-polarizer Stokes inversion and
returns:

- total brightness, `tB`;
- polarized brightness, `pB`;
- percent polarization;
- Stokes `Q` and `U`.

## Legacy Caveat

The historical daily pipeline calls `DO_POLARIZ` with `/VIG`, `/PTF`,
`/SAVE_POLARIZ`, `/SAVE_PERCENT`, and for C3 `/FIXC3ZERO`. That routine is not
part of the mirrored LASCO REDUCE archive, so exact PTF behavior still requires
the missing IDL source or parity fixtures.
