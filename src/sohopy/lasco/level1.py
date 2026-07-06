"""Level 1 LASCO reduction orchestration."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import numpy as np
from astropy.io import fits

from .calibration import calibrate_image
from .config import LASCOConfig
from .geometry import apply_distortion_correction, apply_time_and_roll_correction
from .headers import normalize_lasco_header
from .io import read_lasco_fits, write_lasco_fits
from .missing_blocks import mb_to_string_map, missing_block_mask
from .statistics import add_level1_statistics, scale_c3_clear_to_int16


@dataclass(slots=True)
class Level1Result:
    """Result returned by `reduce_level_1`."""

    image: np.ndarray
    header: fits.Header
    output_path: Path | None = None


def reduce_level_1(
    input_path: str | Path,
    *,
    config: LASCOConfig,
    output_path: str | Path | None = None,
    overwrite: bool = False,
) -> Level1Result:
    """Reduce a LASCO Level 0.5 FITS file to a Level 1 science product.

    This is the public entry point that will replace `reduce_level_1.pro`.
    The orchestration is intentionally present before the full numerical port so
    callers can settle on API shape while parity work proceeds.
    """

    image, header = read_lasco_fits(input_path)
    header = normalize_lasco_header(header)
    calibrated = calibrate_image(image, header, config=config)
    calibrated = apply_distortion_correction(calibrated, header, config=config)
    header = apply_time_and_roll_correction(header, config=config)

    header["LEVEL"] = "1.0"
    header["BUNIT"] = ("MSB", "Mean Solar Brightness")
    block_mask = missing_block_mask(image)
    header["NMISSING"] = (
        int(block_mask.size - np.count_nonzero(block_mask)),
        "Number of missing blocks.",
    )
    header["MISSLIST"] = mb_to_string_map(block_mask) or "None"
    header = add_level1_statistics(calibrated, header)

    detector = str(header.get("DETECTOR", "")).strip().upper()
    filter_name = str(header.get("FILTER", "")).strip().upper()
    output_image = calibrated
    if detector == "C3" and filter_name == "CLEAR":
        output_image, header = scale_c3_clear_to_int16(calibrated, header)

    written_path = Path(output_path) if output_path is not None else None
    if written_path is not None:
        write_lasco_fits(written_path, output_image, header, overwrite=overwrite)

    return Level1Result(image=output_image, header=header, output_path=written_path)
