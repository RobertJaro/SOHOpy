"""FITS I/O helpers for LASCO products."""

from __future__ import annotations

from pathlib import Path
from typing import Any

import numpy as np
from astropy.io import fits


def read_lasco_fits(path: str | Path) -> tuple[np.ndarray, fits.Header]:
    """Read a LASCO FITS image and return a floating image plus header."""

    with fits.open(path, memmap=False) as hdul:
        data = np.asarray(hdul[0].data, dtype=np.float64)
        header = hdul[0].header.copy()
    return data, header


def write_lasco_fits(
    path: str | Path,
    data: np.ndarray,
    header: fits.Header | dict[str, Any],
    *,
    overwrite: bool = False,
) -> None:
    """Write a LASCO FITS image."""

    fits.PrimaryHDU(data=data, header=fits.Header(header)).writeto(
        path,
        overwrite=overwrite,
    )
