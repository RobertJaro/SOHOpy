"""LASCO FITS statistics helpers."""

from __future__ import annotations

import numpy as np
from astropy.io import fits

PERCENTILES = (1, 10, 25, 50, 75, 90, 95, 98, 99)
LEVEL05_PERCENTILES = (1, 10, 25, 75, 90, 95, 98, 99)


def add_level1_statistics(
    image: np.ndarray,
    header: fits.Header,
    *,
    satmax: float | None = None,
    satmin: float | None = None,
) -> fits.Header:
    """Add Level 1 statistics keywords to a FITS header."""

    out = header.copy()
    data = np.asarray(image, dtype=np.float64)
    positive = data[data > 0]
    if positive.size == 0:
        return out

    mn = float(np.min(positive))
    mx = float(np.max(positive))
    mxval = float(satmax) if satmax is not None else float("inf")
    mnval = float(satmin) if satmin is not None else mn
    below_sat = data[data < mxval]
    dmx = float(np.max(below_sat)) if below_sat.size else mx

    out["DATAMIN"] = (mn, "Minimum Value Not Equal to Zero before BSCALE")
    out["DATAMAX"] = (dmx, "Maximum Value before BSCALE")
    out["DATAZER"] = (int(data.size - positive.size), "Number of Zero Pixels")
    out["DATASAT"] = (int(data.size - below_sat.size), "Number of Saturated Pixels")
    out["DSATVAL"] = (mxval if np.isfinite(mxval) else mx, "Value used as saturated")
    out["DSATMIN"] = (mnval, "Minimum value in scaled image")
    out["NSATMIN"] = (
        int(np.count_nonzero((data < mnval) & (data != 0))),
        "Number of pixels cut off on lower end",
    )
    out["DATAAVG"] = (float(np.mean(positive)), "Mean of Image before BSCALE")
    out["DATASIG"] = (
        float(np.std(positive, ddof=1)) if positive.size > 1 else 0.0,
        "Standard Deviation of Image before BSCALE",
    )
    for percentile in PERCENTILES:
        out[f"DATAP{percentile:02d}"] = (
            float(np.percentile(positive, percentile)),
            "Percentile Value",
        )
    return out


def add_level05_statistics(image: np.ndarray, header: fits.Header) -> fits.Header:
    """Add Level 0.5 statistics keywords like `reduce_statistics.pro`."""

    out = header.copy()
    data = np.asarray(image)
    nonzero = data[data != 0]
    if nonzero.size < 1:
        return out

    mn = float(np.min(nonzero))
    mx = float(np.max(nonzero))
    saturation_value = 16383
    valid = data[(data != 0) & (data != saturation_value) & (data != 0xFFFF)]
    nsat = 0.0
    if mx == saturation_value:
        nsat = 1.0 - valid.size / float(data.size) if data.size else 0.0
        if valid.size:
            mx = float(np.max(valid))

    out["DATAMIN"] = mn
    out["DATAMAX"] = mx
    out["DATAZER"] = int(data.size - nonzero.size)
    out["DATASAT"] = nsat
    if valid.size < 4:
        return out

    out["DATAAVG"] = float(np.mean(valid))
    out["DATASIG"] = float(np.std(valid, ddof=1))
    for percentile in LEVEL05_PERCENTILES:
        out[f"DATAP{percentile:02d}"] = int(np.percentile(valid, percentile))
    return out


def standard_intensity_scale(
    image: np.ndarray,
    header: fits.Header,
    *,
    bias: float | None = None,
) -> np.ndarray:
    """Scale image to DN/sec like `std_int_scale.pro`.

    The legacy routine obtains `bias` from `OFFSET_BIAS(hdr)`, which lives
    outside the mirrored REDUCE archive. Python callers can pass it explicitly;
    otherwise the FITS `OFFSET` keyword is used with a default of zero.
    """

    offset = float(header.get("OFFSET", 0.0) if bias is None else bias)
    leb_sum = int(header.get("LEBXSUM", 1) or 1) * int(header.get("LEBYSUM", 1) or 1)
    ccd_sum = max(int(header.get("COLSUM", header.get("SUMCOL", 1)) or 1), 1) * max(
        int(header.get("ROWSUM", header.get("SUMROW", 1)) or 1),
        1,
    )
    exptime = float(header.get("EXPTIME", 1.0) or 1.0)
    return (np.asarray(image, dtype=np.float64) - offset * leb_sum) / (
        float(leb_sum * ccd_sum) * exptime
    )


def scale_c3_clear_to_int16(
    image: np.ndarray,
    header: fits.Header,
    *,
    scalemin: float = 0.0,
    scalemax: float = 6.5e-9,
) -> tuple[np.ndarray, fits.Header]:
    """Scale C3 clear Level 1 images like `reduce_level_1.pro`."""

    out = header.copy()
    data = np.asarray(image, dtype=np.float64)
    bscale = (scalemax - scalemin) / 65536.0
    bzero = bscale * 32769.0
    scaled = np.zeros(data.shape, dtype=np.int16)
    nonzero = data != 0
    clipped = np.clip(data[nonzero], scalemin, scalemax)
    scaled[nonzero] = np.rint((clipped - bzero) / bscale).astype(np.int16)
    out["BSCALE"] = (bscale, "Data value = FITS value x BSCALE + BZERO")
    out["BZERO"] = bzero
    out["BLANK"] = -32768
    out.add_comment(f"Data is scaled between {scalemin} and {scalemax}")
    out.add_comment("Percentile values are before scaling.")
    return scaled, out
