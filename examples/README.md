# SOHOpy Examples

These examples are intentionally small and runnable without external SOHO data.
They demonstrate the public API and the calibration-file layout expected by the
LASCO port.

Run from the repository root after activating the `sohopy` environment:

```bash
conda activate sohopy
python examples/lasco_level1_synthetic.py
python examples/lasco_polarization_synthetic.py
python scripts/run_lasco_synthetic_workflow.py --output-dir runs/lasco_synthetic_workflow
```

The synthetic example creates temporary C2 Level 0.5-like FITS data and a simple
vignetting file, runs `reduce_level_1`, and reports the generated Level 1 FITS
path.

The polarization example creates an ideal calibrated `-60/0/+60` triplet and
writes synthetic tB and pB FITS products.

The full workflow script writes FITS and PNG products to a persistent output
directory. It exercises calibration cache inspection, Level 1 processing,
polarization products, and visualization helpers in one run.
