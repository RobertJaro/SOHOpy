"""Geometry hooks for LASCO reduction."""

from __future__ import annotations

import numpy as np
from astropy.io import fits

from .config import LASCOConfig
from .exceptions import UnsupportedReductionStepError


def _idl_rotate(image: np.ndarray, code: int) -> np.ndarray:
    """Approximate IDL `ROTATE` codes used by LASCO rectification."""

    data = np.asarray(image)
    if code == 1:
        return np.rot90(data, 1)
    if code == 2:
        return np.rot90(data, 2)
    if code == 3:
        return np.rot90(data, 3)
    if code == 4:
        return data.T
    if code == 5:
        return np.rot90(data.T, 1)
    if code == 6:
        return np.rot90(data.T, 2)
    if code == 7:
        return np.rot90(data.T, 3)
    raise ValueError(f"Unsupported IDL ROTATE code: {code}")


def rectify_p1p2(header: fits.Header, effective_port: str) -> fits.Header:
    """Generate rectified R1/R2 coordinates like `reduce_rectify_p1p2.pro`."""

    out = header.copy()
    p1col = int(out.get("P1COL"))
    p1row = int(out.get("P1ROW"))
    p2col = int(out.get("P2COL"))
    p2row = int(out.get("P2ROW"))
    effport = effective_port.strip().upper()

    if effport == "A":
        r1col, r2col = p1row + 19, p2row + 19
        r1row, r2row = 1044 - p2col, 1044 - p1col
    elif effport == "B":
        r1col, r2col = p1row + 19, p2row + 19
        r1row, r2row = p1col - 19, p2col - 19
    elif effport == "C":
        r1col, r2col = 1044 - p2row, 1044 - p1row
        r1row, r2row = 1044 - p2col, 1044 - p1col
    elif effport == "D":
        r1col, r2col = 1044 - p2row, 1044 - p1row
        r1row, r2row = p1col - 19, p2col - 19
    else:
        r1col, r2col = p1col, p2col
        r1row, r2row = p1row, p2row

    if r1col < 1:
        r2col = r2col + abs(r1col) + 1
        r1col = 1
    if r1row < 1:
        r2row = r2row + abs(r1row) + 1
        r1row = 1

    out["R1COL"] = r1col
    out["R1ROW"] = r1row
    out["R2COL"] = r2col
    out["R2ROW"] = r2row
    out["EFFPORT"] = effport
    return out


def reduce_rectify(
    image: np.ndarray,
    header: fits.Header,
) -> tuple[np.ndarray, fits.Header]:
    """Rectify CCD readout orientation like `reduce_rectify.pro`."""

    out = header.copy()
    readport = str(out.get("READPORT", "")).strip().upper()
    detector = str(out.get("DETECTOR", "")).strip().upper()

    if detector == "C1":
        code_by_port = {"A": 5, "B": None, "C": 2, "D": 7}
    else:
        code_by_port = {"A": 3, "B": 4, "C": 6, "D": 1}
        out = rectify_p1p2(out, readport)

    if readport not in code_by_port:
        out["RECTIFY"] = "FALSE"
        return np.array([-1]), out

    code = code_by_port[readport]
    rectified = np.asarray(image) if code is None else _idl_rotate(image, code)
    if detector != "C1":
        out["NAXIS1"], out["NAXIS2"] = int(out.get("NAXIS2")), int(out.get("NAXIS1"))
    out["RECTIFY"] = "TRUE"
    return rectified, out


def apply_distortion_correction(
    image: np.ndarray,
    header: fits.Header,
    *,
    config: LASCOConfig,
) -> np.ndarray:
    """Apply C2/C3 distortion correction when a port is available."""

    if not config.apply_distortion:
        return image
    detector = str(header.get("DETECTOR", "")).strip().upper()
    raise UnsupportedReductionStepError(
        f"{detector} distortion correction depends on legacy c2_warp/c3_warp "
        "routines that are outside the mirrored LASCO REDUCE archive."
    )


def apply_time_and_roll_correction(
    header: fits.Header,
    *,
    config: LASCOConfig,
) -> fits.Header:
    """Apply time, sun-center, and roll corrections when ports are available."""

    if not config.correct_time and not config.correct_roll:
        return header.copy()
    raise UnsupportedReductionStepError(
        "Time/roll/sun-center correction depends on adjust_hdr_tcr, "
        "get_sun_center, and related SolarSoft routines outside this archive."
    )
