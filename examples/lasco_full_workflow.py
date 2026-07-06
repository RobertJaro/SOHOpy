"""Run the complete synthetic LASCO workflow and write preview images."""

from __future__ import annotations

from pathlib import Path
from tempfile import TemporaryDirectory

import numpy as np
from astropy.io import fits

from sohopy.lasco import (
    LASCOConfig,
    combine_polarizer_triplet_files,
    inspect_calibration_assets,
    plot_fits_image,
    plot_polarization_summary,
    reduce_level_1,
    write_polarization_products,
)


def create_synthetic_lasco_scene(path: Path) -> None:
    """Create a C2 Level 0.5-like input with a smooth coronal signal."""

    y, x = np.indices((128, 128), dtype=np.float64)
    radius = np.hypot(x - 64.0, y - 64.0)
    streamer = 18.0 * np.exp(-((x - 82.0) ** 2) / 180.0) * np.exp(
        -((y - 72.0) ** 2) / 900.0
    )
    corona = 10.0 + 70.0 / (1.0 + radius / 12.0) + streamer
    occulting_disk = radius < 18.0
    data = corona.copy()
    data[occulting_disk] = 0.0

    header = fits.Header()
    header["DETECTOR"] = "C2"
    header["FILTER"] = "Orange"
    header["POLAR"] = "CLEAR"
    header["DATE-OBS"] = "2005-01-01T00:00:00.000"
    header["EXPTIME"] = 2.5
    header["OFFSET"] = 1.0
    header["SUMCOL"] = 1
    header["SUMROW"] = 1
    header["LEBXSUM"] = 1
    header["LEBYSUM"] = 1
    fits.PrimaryHDU(data=data, header=header).writeto(path, overwrite=True)


def create_synthetic_calibration_cache(calibration_root: Path) -> None:
    """Create deterministic calibration assets for the synthetic workflow."""

    y, x = np.indices((128, 128), dtype=np.float64)
    radius = np.hypot(x - 64.0, y - 64.0)
    vignette = 1.0 + 0.12 * radius / radius.max()
    fits.PrimaryHDU(vignette).writeto(
        calibration_root / "c2vig_final.fts",
        overwrite=True,
    )


def create_synthetic_polarizer_triplet(workdir: Path) -> tuple[Path, Path, Path]:
    """Create an ideal calibrated C2 polarizer triplet."""

    y, x = np.indices((96, 96), dtype=np.float64)
    radius = np.hypot(x - 48.0, y - 48.0)
    total = 12.0 + 30.0 / (1.0 + radius / 10.0)
    q = 0.18 * total * np.cos(np.arctan2(y - 48.0, x - 48.0))
    u = 0.12 * total * np.sin(np.arctan2(y - 48.0, x - 48.0))

    minus_60 = 0.5 * (total - 0.5 * q - np.sqrt(3.0) / 2.0 * u)
    zero = 0.5 * (total + q)
    plus_60 = 0.5 * (total - 0.5 * q + np.sqrt(3.0) / 2.0 * u)

    header = fits.Header({"DETECTOR": "C2", "BUNIT": "MSB"})
    paths = (
        workdir / "c2_m60.fts",
        workdir / "c2_0.fts",
        workdir / "c2_p60.fts",
    )
    for path, data in zip(paths, (minus_60, zero, plus_60), strict=True):
        fits.PrimaryHDU(data, header=header).writeto(path, overwrite=True)
    return paths


def run_workflow(output_dir: Path) -> dict[str, Path]:
    """Run a complete synthetic reduction, polarization, and plotting workflow."""

    output_dir.mkdir(parents=True, exist_ok=True)
    calibration_root = output_dir / "calibration"
    calibration_root.mkdir(exist_ok=True)
    create_synthetic_calibration_cache(calibration_root)

    level05 = output_dir / "c2_level05_synthetic.fts"
    level1 = output_dir / "c2_level1_synthetic.fts"
    level1_png = output_dir / "c2_level1_synthetic.png"
    create_synthetic_lasco_scene(level05)

    statuses = inspect_calibration_assets(calibration_root)
    present = [status.filename for status in statuses if status.exists]
    print(f"Calibration assets present: {', '.join(present)}")

    reduce_level_1(
        level05,
        config=LASCOConfig(calibration_root=calibration_root),
        output_path=level1,
        overwrite=True,
    )
    plot_fits_image(level1, level1_png, title="Synthetic C2 Level 1")

    minus_60, zero, plus_60 = create_synthetic_polarizer_triplet(output_dir)
    pol = combine_polarizer_triplet_files(minus_60, zero, plus_60)
    tb_path = output_dir / "c2_tB_synthetic.fts"
    pb_path = output_dir / "c2_pB_synthetic.fts"
    pol_png = output_dir / "c2_polarization_summary.png"
    write_polarization_products(
        pol,
        total_brightness_path=tb_path,
        polarized_brightness_path=pb_path,
        overwrite=True,
    )
    plot_polarization_summary(pol.tB, pol.pB, pol.percent_polarization, pol_png)

    outputs = {
        "level05": level05,
        "level1": level1,
        "level1_png": level1_png,
        "tb": tb_path,
        "pb": pb_path,
        "polarization_png": pol_png,
    }
    for name, path in outputs.items():
        print(f"{name}: {path}")
    return outputs


def main() -> None:
    with TemporaryDirectory(prefix="sohopy-workflow-") as tmp:
        outputs = run_workflow(Path(tmp))
        print(f"Workflow complete in {Path(tmp)}")
        print(f"Preview PNG: {outputs['level1_png']}")


if __name__ == "__main__":
    main()
