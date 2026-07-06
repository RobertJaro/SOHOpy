"""Create synthetic LASCO tB/pB products from a polarizer triplet."""

from __future__ import annotations

import math
from pathlib import Path
from tempfile import TemporaryDirectory

import numpy as np
from astropy.io import fits

from sohopy.lasco import combine_polarizer_triplet_files, write_polarization_products


def _ideal_measurements(total: float, q: float, u: float) -> tuple[float, float, float]:
    minus_60 = 0.5 * (total - 0.5 * q - math.sqrt(3.0) / 2.0 * u)
    zero = 0.5 * (total + q)
    plus_60 = 0.5 * (total - 0.5 * q + math.sqrt(3.0) / 2.0 * u)
    return minus_60, zero, plus_60


def run_example(workdir: Path) -> tuple[Path, Path]:
    minus_60, zero, plus_60 = _ideal_measurements(total=12.0, q=3.0, u=4.0)
    header = fits.Header({"DETECTOR": "C2", "BUNIT": "MSB"})
    paths = {
        "minus": workdir / "c2_m60.fts",
        "zero": workdir / "c2_0.fts",
        "plus": workdir / "c2_p60.fts",
    }
    fits.PrimaryHDU(np.full((32, 32), minus_60), header=header).writeto(
        paths["minus"]
    )
    fits.PrimaryHDU(np.full((32, 32), zero), header=header).writeto(paths["zero"])
    fits.PrimaryHDU(np.full((32, 32), plus_60), header=header).writeto(paths["plus"])

    result = combine_polarizer_triplet_files(
        paths["minus"],
        paths["zero"],
        paths["plus"],
    )
    tb_path = workdir / "c2_tB.fts"
    pb_path = workdir / "c2_pB.fts"
    write_polarization_products(
        result,
        total_brightness_path=tb_path,
        polarized_brightness_path=pb_path,
        overwrite=True,
    )
    print(f"tB mean: {float(np.mean(result.tB)):.3f}")
    print(f"pB mean: {float(np.mean(result.pB)):.3f}")
    return tb_path, pb_path


def main() -> None:
    with TemporaryDirectory(prefix="sohopy-pol-") as tmp:
        tb_path, pb_path = run_example(Path(tmp))
        print(f"Wrote {tb_path}")
        print(f"Wrote {pb_path}")


if __name__ == "__main__":
    main()
