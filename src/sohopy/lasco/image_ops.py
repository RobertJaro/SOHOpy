"""Image operations used by LASCO calibration routines."""

from __future__ import annotations

import numpy as np
from astropy.io import fits
from scipy.ndimage import zoom


def roi_slices(header: fits.Header) -> tuple[slice, slice] | None:
    """Return NumPy slices for a LASCO ROI, or `None` for full frame."""

    r1col = int(header.get("R1COL", 20))
    r1row = int(header.get("R1ROW", 1))
    r2col = int(header.get("R2COL", 1043))
    r2row = int(header.get("R2ROW", 1024))
    if (r1col, r1row, r2col, r2row) == (20, 1, 1043, 1024) or r2col == 0:
        return None
    return slice(r1row - 1, r2row), slice(r1col - 20, r2col - 19)


def crop_to_lasco_roi(array: np.ndarray, header: fits.Header) -> np.ndarray:
    """Crop a full-frame calibration array to the ROI described by a header."""

    slices = roi_slices(header)
    if slices is None:
        return np.asarray(array, dtype=np.float64)
    return np.asarray(array[slices], dtype=np.float64)


def rebin_mean(array: np.ndarray, factor_y: int, factor_x: int) -> np.ndarray:
    """Downsample a 2D array by block averaging, matching IDL `rebin` use."""

    if factor_x == 1 and factor_y == 1:
        return np.asarray(array, dtype=np.float64)
    if factor_x < 1 or factor_y < 1:
        raise ValueError("Rebin factors must be positive.")
    ny, nx = array.shape
    if ny % factor_y or nx % factor_x:
        raise ValueError(
            f"Cannot rebin shape {(ny, nx)} by factors {(factor_y, factor_x)}."
        )
    return array.reshape(ny // factor_y, factor_y, nx // factor_x, factor_x).mean(
        axis=(1, 3)
    )


def apply_summing_to_calibration(array: np.ndarray, header: fits.Header) -> np.ndarray:
    """Apply on-chip and LEB summing to a calibration image."""

    out = np.asarray(array, dtype=np.float64)
    sumcol = max(int(header.get("SUMCOL", 1)), 1)
    sumrow = max(int(header.get("SUMROW", 1)), 1)
    lebxsum = max(int(header.get("LEBXSUM", 1)), 1)
    lebysum = max(int(header.get("LEBYSUM", 1)), 1)
    out = rebin_mean(out, sumrow, sumcol)
    out = rebin_mean(out, lebysum, lebxsum)
    return out


def histogram_equalize_to_uint8(image: np.ndarray) -> np.ndarray:
    """Histogram-equalize an image to bytes like the browse-image path."""

    data = np.asarray(image, dtype=np.float64)
    finite = np.isfinite(data)
    if not np.any(finite):
        return np.zeros(data.shape, dtype=np.uint8)
    values = data[finite]
    if np.nanmax(values) == np.nanmin(values):
        return np.zeros(data.shape, dtype=np.uint8)

    ranks = np.searchsorted(np.sort(values), data, side="right")
    scaled = np.zeros(data.shape, dtype=np.float64)
    scaled[finite] = 255.0 * ranks[finite] / values.size
    return np.clip(scaled, 0, 255).astype(np.uint8)


def make_browse_image(image: np.ndarray, maxpix: int = 128) -> np.ndarray:
    """Create an uncompressed browse image similar to `make_browse.pro`."""

    data = np.asarray(image)
    if data.ndim != 2:
        raise ValueError("Browse images require 2D input.")
    nr, nc = data.shape
    if nc > nr:
        out_nx = maxpix
        out_ny = max(1, int(nr * maxpix / nc))
    elif nc < nr:
        out_ny = maxpix
        out_nx = max(1, int(nc * maxpix / nr))
    else:
        out_nx = out_ny = maxpix

    if max(nc, nr) <= maxpix:
        browse = data.astype(np.float64, copy=False)
    else:
        browse = zoom(
            data.astype(np.float64, copy=False),
            (out_ny / nr, out_nx / nc),
            order=1,
        )
    return histogram_equalize_to_uint8(browse)
