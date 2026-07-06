"""LASCO polarization products from calibrated polarizer triplets."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import numpy as np
from astropy.io import fits

from .headers import normalize_lasco_header
from .io import read_lasco_fits, write_lasco_fits


@dataclass(slots=True)
class PolarizationResult:
    """Total/polarized brightness and Stokes products."""

    total_brightness: np.ndarray
    polarized_brightness: np.ndarray
    percent_polarization: np.ndarray
    stokes_q: np.ndarray
    stokes_u: np.ndarray
    header: fits.Header

    @property
    def tB(self) -> np.ndarray:
        """Alias for total brightness."""

        return self.total_brightness

    @property
    def pB(self) -> np.ndarray:
        """Alias for polarized brightness."""

        return self.polarized_brightness


def combine_polarizer_triplet(
    minus_60: np.ndarray,
    zero: np.ndarray,
    plus_60: np.ndarray,
    *,
    header: fits.Header | None = None,
) -> PolarizationResult:
    """Combine calibrated LASCO `-60/0/+60` images into tB and pB.

    This uses the ideal three-polarizer Stokes inversion. The legacy LASCO
    pipeline calls `DO_POLARIZ` with a PTF correction, but that routine is
    outside the mirrored REDUCE archive. Inputs here should already be Level 1
    calibrated, coaligned, and corrected for any desired PTF effects.
    """

    im_minus = np.asarray(minus_60, dtype=np.float64)
    im_zero = np.asarray(zero, dtype=np.float64)
    im_plus = np.asarray(plus_60, dtype=np.float64)
    if im_minus.shape != im_zero.shape or im_zero.shape != im_plus.shape:
        raise ValueError("Polarizer triplet images must have identical shapes.")

    total_brightness = (2.0 / 3.0) * (im_minus + im_zero + im_plus)
    stokes_q = (2.0 / 3.0) * (2.0 * im_zero - im_plus - im_minus)
    stokes_u = (2.0 / np.sqrt(3.0)) * (im_plus - im_minus)
    polarized_brightness = np.hypot(stokes_q, stokes_u)
    percent_polarization = np.zeros_like(total_brightness)
    valid = total_brightness != 0
    percent_polarization[valid] = (
        100.0 * polarized_brightness[valid] / total_brightness[valid]
    )

    out_header = fits.Header() if header is None else header.copy()
    out_header["POLAR"] = ("PB", "Polarized brightness from polarizer triplet")
    out_header["BUNIT"] = ("MSB", "Mean Solar Brightness")
    out_header["HISTORY"] = "SOHOpy ideal -60/0/+60 polarizer inversion"
    return PolarizationResult(
        total_brightness=total_brightness,
        polarized_brightness=polarized_brightness,
        percent_polarization=percent_polarization,
        stokes_q=stokes_q,
        stokes_u=stokes_u,
        header=out_header,
    )


def combine_polarizer_triplet_files(
    minus_60_path: str | Path,
    zero_path: str | Path,
    plus_60_path: str | Path,
) -> PolarizationResult:
    """Read three calibrated FITS images and compute tB/pB products."""

    minus_60, header = read_lasco_fits(minus_60_path)
    zero, _ = read_lasco_fits(zero_path)
    plus_60, _ = read_lasco_fits(plus_60_path)
    return combine_polarizer_triplet(
        minus_60,
        zero,
        plus_60,
        header=normalize_lasco_header(header),
    )


def write_polarization_products(
    result: PolarizationResult,
    *,
    total_brightness_path: str | Path | None = None,
    polarized_brightness_path: str | Path | None = None,
    percent_polarization_path: str | Path | None = None,
    overwrite: bool = False,
) -> None:
    """Write selected tB, pB, and percent-polarization FITS products."""

    if total_brightness_path is not None:
        header = result.header.copy()
        header["POLAR"] = ("TB", "Total brightness")
        write_lasco_fits(
            total_brightness_path,
            result.total_brightness,
            header,
            overwrite=overwrite,
        )
    if polarized_brightness_path is not None:
        header = result.header.copy()
        header["POLAR"] = ("PB", "Polarized brightness")
        write_lasco_fits(
            polarized_brightness_path,
            result.polarized_brightness,
            header,
            overwrite=overwrite,
        )
    if percent_polarization_path is not None:
        header = result.header.copy()
        header["POLAR"] = ("%P", "Percent polarization")
        header["BUNIT"] = ("percent", "Percent polarization")
        write_lasco_fits(
            percent_polarization_path,
            result.percent_polarization,
            header,
            overwrite=overwrite,
        )
