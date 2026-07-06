"""Run a synthetic LASCO C2 Level 1 reduction.

This example is deliberately self-contained: it creates tiny FITS files in a
temporary directory, runs SOHOpy's LASCO Level 1 entry point, and prints a compact
summary. Real reductions should point `LASCOConfig.calibration_root` at the
directory containing the LASCO calibration FITS assets.
"""

from __future__ import annotations

from pathlib import Path
from tempfile import TemporaryDirectory

import numpy as np
from astropy.io import fits

from sohopy.lasco import LASCOConfig, reduce_level_1


def create_synthetic_c2_input(path: Path) -> None:
    """Create a small C2 FITS image with enough metadata for calibration."""

    header = fits.Header()
    header["DETECTOR"] = "C2"
    header["FILTER"] = "Orange"
    header["POLAR"] = "CLEAR"
    header["DATE-OBS"] = "2005-01-01T00:00:00.000"
    header["EXPTIME"] = 2.0
    header["OFFSET"] = 1.0
    header["SUMCOL"] = 1
    header["SUMROW"] = 1
    header["LEBXSUM"] = 1
    header["LEBYSUM"] = 1
    data = np.full((64, 64), 10.0)
    fits.PrimaryHDU(data=data, header=header).writeto(path)


def create_synthetic_calibration_assets(calibration_root: Path) -> None:
    """Create the minimal C2 vignetting asset required by this example."""

    fits.PrimaryHDU(data=np.ones((64, 64))).writeto(
        calibration_root / "c2vig_final.fts"
    )


def run_example(workdir: Path) -> Path:
    """Create synthetic inputs, run reduction, and return the output path."""

    input_path = workdir / "c2_level05_synthetic.fts"
    output_path = workdir / "c2_level1_synthetic.fts"
    create_synthetic_c2_input(input_path)
    create_synthetic_calibration_assets(workdir)

    result = reduce_level_1(
        input_path,
        config=LASCOConfig(calibration_root=workdir),
        output_path=output_path,
        overwrite=True,
    )
    print(f"Wrote {result.output_path}")
    mean_value = float(np.mean(result.image))
    print(f"Mean calibrated value: {mean_value:.6e} {result.header['BUNIT']}")
    return output_path


def main() -> None:
    with TemporaryDirectory(prefix="sohopy-lasco-") as tmp:
        output_path = run_example(Path(tmp))
        with fits.open(output_path) as hdul:
            print(f"Output shape: {hdul[0].data.shape}")
            print(f"NMISSING: {hdul[0].header['NMISSING']}")


if __name__ == "__main__":
    main()
