"""Small deterministic LASCO REDUCE helpers ported from IDL."""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np
from astropy.io import fits


@dataclass(frozen=True, slots=True)
class OBESummingCheck:
    """Result of the `check_obesumerror.pro` consistency test."""

    mismatch: bool
    expected_shape: tuple[int, int]
    actual_shape: tuple[int, int]
    factor_x: int = 1
    factor_y: int = 1


def check_obe_summing_error(
    image: np.ndarray,
    header: fits.Header,
    *,
    fix: bool = False,
) -> tuple[OBESummingCheck, fits.Header]:
    """Check and optionally repair the 1997 OBE LEB summing header error."""

    out = header.copy()
    data = np.asarray(image)
    if data.ndim != 2:
        raise ValueError("OBE summing checks require a 2D image.")
    actual_y, actual_x = data.shape
    ncol = int(out.get("R2COL", actual_x) or actual_x) - int(out.get("R1COL", 1)) + 1
    nrow = int(out.get("R2ROW", actual_y) or actual_y) - int(out.get("R1ROW", 1)) + 1
    xsum = int(out.get("LEBXSUM", 1) or 1) * max(int(out.get("SUMCOL", 1) or 1), 1)
    ysum = int(out.get("LEBYSUM", 1) or 1) * max(int(out.get("SUMROW", 1) or 1), 1)
    expected_x = ncol // xsum
    expected_y = nrow // ysum
    mismatch = expected_x != actual_x or expected_y != actual_y
    factor_x = expected_x // actual_x if mismatch and actual_x else 1
    factor_y = expected_y // actual_y if mismatch and actual_y else 1

    if fix and mismatch:
        out["LEBXSUM"] = (factor_x, "Fixed OBE summing mismatch")
        out["LEBYSUM"] = (factor_y, "Fixed OBE summing mismatch")

    return (
        OBESummingCheck(
            mismatch=mismatch,
            expected_shape=(expected_y, expected_x),
            actual_shape=(actual_y, actual_x),
            factor_x=factor_x,
            factor_y=factor_y,
        ),
        out,
    )


def telescope_configuration(header: fits.Header) -> int:
    """Compute LASCO telescope/camera config, correcting `get_tel_config.pro`.

    The IDL routine references an undefined `door` variable and then uses the
    string `readport` in arithmetic after computing numeric `port`. This port
    uses `DOOR` when present, otherwise zero, and uses the numeric port.
    """

    filt = int(header.get("FILTER", 0) or 0)
    polar = int(header.get("POLAR", 0) or 0)
    door = int(header.get("DOOR", 0) or 0)
    lamp = int(header.get("LAMP", 0) or 0)
    sumcol = int(header.get("SUMCOL", 1) or 1)
    sumrow = int(header.get("SUMROW", 1) or 1)
    clrmode = int(header.get("CLRMODE", 0) or 0)
    readport = str(header.get("READPORT", "A")).strip().upper()
    port = {"A": 0, "B": 1, "C": 2, "D": 3}.get(readport)
    if port is None:
        raise ValueError(f"Invalid LASCO readport: {readport!r}")

    tel_mode = filt + 5 * polar + 25 * door + 50 * lamp
    cam_mode = min(sumcol, 5) + 6 * min(sumrow, 5) + 36 * port + 144 * clrmode
    return tel_mode + 200 * cam_mode


def dark_bias_statistics(
    image: np.ndarray,
    *,
    offset_bias: float = 0.0,
    sigma_cut: float = 10.0,
) -> dict[str, float]:
    """Return dark image statistics from `calc_dark_bias.pro` without file I/O."""

    data = np.asarray(image, dtype=np.float64)
    values = data[data != 0]
    if values.size == 0:
        return {
            "mean": float("nan"),
            "sigma": float("nan"),
            "median": float("nan"),
            "num_rejected": 0,
            "offset_bias": float(offset_bias),
        }
    median = float(np.median(values))
    mean = float(np.mean(values))
    sigma = float(np.std(values, ddof=1)) if values.size > 1 else 0.0
    if sigma > 0:
        keep = np.abs(values - mean) <= sigma_cut * sigma
        rejected = int(values.size - np.count_nonzero(keep))
        clipped = values[keep]
        mean = float(np.mean(clipped)) if clipped.size else mean
        sigma = float(np.std(clipped, ddof=1)) if clipped.size > 1 else 0.0
    else:
        rejected = 0
    return {
        "mean": mean,
        "sigma": sigma,
        "median": median,
        "num_rejected": rejected,
        "offset_bias": float(offset_bias),
    }
