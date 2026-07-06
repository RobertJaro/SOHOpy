"""Calibration primitives for LASCO C2 and C3 images."""

from __future__ import annotations

import numpy as np
from astropy.io import fits

from .assets import c2_vignetting, c3_mask, c3_ramp, c3_vignetting
from .config import LASCOConfig
from .exceptions import UnsupportedReductionStepError
from .image_ops import apply_summing_to_calibration, crop_to_lasco_roi
from .time import observation_mjd

POLARIZATION_PRODUCTS = frozenset(
    {"PB", "TI", "UP", "JY", "JZ", "QS", "US", "QT", "JR", "JT"}
)
POLARIZER_TRANSMISSION = 0.25256


def _compact(value: object) -> str:
    return str(value or "").strip().replace(" ", "").upper()


def _header_float(header: fits.Header, key: str, default: float) -> float:
    value = header.get(key, default)
    if value in ("", None):
        return default
    return float(value)


def _summing_correct(header: fits.Header, factor: float) -> float:
    for key, minimum in (("SUMCOL", 1), ("SUMROW", 1), ("LEBXSUM", 2), ("LEBYSUM", 2)):
        value = int(header.get(key, 1) or 1)
        if value >= minimum:
            factor /= value
    return factor


def calibration_factor(header: fits.Header, *, correct_summing: bool = True) -> float:
    """Return the LASCO photometric calibration factor for a FITS header."""

    detector = str(header.get("DETECTOR", "")).strip().upper()
    if detector == "C2":
        return c2_calibration_factor(header, correct_summing=correct_summing)
    if detector == "C3":
        return c3_calibration_factor(header, correct_summing=correct_summing)
    raise ValueError(f"Unsupported LASCO detector: {detector!r}")


def c2_calibration_factor(
    header: fits.Header,
    *,
    correct_summing: bool = True,
) -> float:
    """Return the C2 factor from `c2_calfactor.pro`.

    The returned units are `(B/Bsun)/(DN/pixel-second)`.
    """

    mjd = observation_mjd(header)
    filter_name = _compact(header.get("FILTER"))
    polarizer = _compact(header.get("POLAR"))
    cal_factor = 0.0

    if filter_name == "ORANGE":
        cal_factor = 4.60403e-7 * mjd + 0.0374116
        polref = cal_factor / POLARIZER_TRANSMISSION
        if polarizer in {"+60DEG", "0DEG", "-60DEG", "ND"}:
            cal_factor = polref
    elif filter_name == "BLUE":
        cal_factor = 0.1033
        polref = cal_factor / POLARIZER_TRANSMISSION
        if polarizer in {"+60DEG", "0DEG", "-60DEG", "ND"}:
            cal_factor = polref
    elif filter_name == "DEEPRD":
        cal_factor = 0.1033
        polref = cal_factor / POLARIZER_TRANSMISSION
        if polarizer in {"+60DEG", "0DEG", "-60DEG", "ND"}:
            cal_factor = polref
        elif polarizer != "CLEAR":
            cal_factor = 0.0
    elif filter_name in {"HALPHA", "LENS"}:
        cal_factor = 0.01055
        polref = cal_factor / POLARIZER_TRANSMISSION
        if polarizer in {"+60DEG", "0DEG", "-60DEG", "ND"}:
            cal_factor = polref

    if correct_summing:
        cal_factor = _summing_correct(header, cal_factor)
    return cal_factor * 1e-10


def c3_calibration_factor(
    header: fits.Header,
    *,
    correct_summing: bool = True,
) -> float:
    """Return the C3 factor from the current `c3_calfactor.pro`."""

    mjd = observation_mjd(header)
    filter_name = _compact(header.get("FILTER"))
    polarizer = _compact(header.get("POLAR"))
    cal_factor = 0.0

    if filter_name == "ORANGE":
        cal_factor = 0.0297
        polref = cal_factor / POLARIZER_TRANSMISSION
        if polarizer == "+60DEG":
            cal_factor = polref
        elif polarizer == "0DEG":
            cal_factor = polref * 0.9648
        elif polarizer == "-60DEG":
            cal_factor = polref * 1.0798
    elif filter_name == "BLUE":
        cal_factor = 0.0975
        polref = cal_factor / POLARIZER_TRANSMISSION
        if polarizer == "+60DEG":
            cal_factor = polref
        elif polarizer == "0DEG":
            cal_factor = polref * 0.9734
        elif polarizer == "-60DEG":
            cal_factor = polref * 1.0613
    elif filter_name == "CLEAR":
        cal_factor = 7.43e-8 * (mjd - 50000.0) + 5.96e-3
        polref = cal_factor / POLARIZER_TRANSMISSION
        if polarizer == "+60DEG":
            cal_factor = polref
        elif polarizer == "0DEG":
            cal_factor = polref * 0.9832
        elif polarizer == "-60DEG":
            cal_factor = polref * 1.0235
        elif polarizer == "H_ALPHA":
            cal_factor = 1.541
        elif polarizer != "CLEAR":
            cal_factor = 0.0
    elif filter_name == "DEEPRD":
        cal_factor = 0.0259
        polref = cal_factor / POLARIZER_TRANSMISSION
        if polarizer == "+60DEG":
            cal_factor = polref
        elif polarizer == "0DEG":
            cal_factor = polref * 0.9983
        elif polarizer == "-60DEG":
            cal_factor = polref * 1.0300
    elif filter_name == "IR":
        cal_factor = 0.0887
        polref = cal_factor / POLARIZER_TRANSMISSION
        if polarizer == "+60DEG":
            cal_factor = polref
        elif polarizer == "0DEG":
            cal_factor = polref * 0.9833
        elif polarizer == "-60DEG":
            cal_factor = polref * 1.0288

    if correct_summing:
        cal_factor = _summing_correct(header, cal_factor)
    return cal_factor * 1e-10


def exposure_factor_and_bias(
    header: fits.Header,
    *,
    config: LASCOConfig,
) -> tuple[float, float]:
    """Return exposure correction factor and CCD bias for a header."""

    if config.exposure_correction is not None:
        return config.exposure_correction(header)
    expfac = _header_float(header, "EXPFAC", 1.0)
    bias = _header_float(header, "OFFSET", 0.0)
    return expfac, bias


def calibrate_image(
    image,
    header: fits.Header,
    *,
    config: LASCOConfig,
):
    """Apply detector-specific LASCO calibration."""

    detector = str(header.get("DETECTOR", "")).strip().upper()
    if detector == "C2":
        return calibrate_c2(image, header, config=config)
    if detector == "C3":
        return calibrate_c3(image, header, config=config)
    raise ValueError(f"Unsupported LASCO detector: {detector!r}")


def calibrate_c2(image, header: fits.Header, *, config: LASCOConfig):
    """Calibrate a C2 image to mean solar brightness units."""

    expfac, bias = exposure_factor_and_bias(header, config=config)
    exptime = _header_float(header, "EXPTIME", 1.0) * expfac
    calfac = c2_calibration_factor(header)
    data = np.asarray(image, dtype=np.float64)
    if _compact(header.get("POLAR")) in POLARIZATION_PRODUCTS:
        calibrated = data * calfac / exptime
    else:
        calibrated = (data - bias) * calfac / exptime

    if config.apply_vignetting:
        vig_image = c2_vignetting(config)
        vig = crop_to_lasco_roi(vig_image.data, header)
        vig = apply_summing_to_calibration(vig, header)
        calibrated = calibrated * vig
        header["C2VIG"] = (vig_image.path.name, "C2 vignetting calibration file")

    header["EXPTIME"] = (exptime, "Corrected exposure time (seconds)")
    header["CALFAC"] = (calfac, "Conversion from DN to MSB")
    header["EXPFAC"] = (expfac, "Exposure time correction factor")
    header["OFFSET"] = (bias, "Corrected CCD offset bias")
    return calibrated


def calibrate_c3(image, header: fits.Header, *, config: LASCOConfig):
    """Calibrate a C3 image to mean solar brightness units."""

    if config.fill_missing_blocks:
        raise UnsupportedReductionStepError(
            "C3 fuzzy missing-block replacement is not ported yet."
        )

    expfac, bias = exposure_factor_and_bias(header, config=config)
    exptime = _header_float(header, "EXPTIME", 1.0) * expfac
    calfac = c3_calibration_factor(header)
    data = np.asarray(image, dtype=np.float64)

    vig = np.ones_like(data, dtype=np.float64)
    if config.apply_vignetting:
        vig_image = c3_vignetting(config, header)
        vig = crop_to_lasco_roi(vig_image.data, header)
        vig = apply_summing_to_calibration(vig, header)
        header["C3VIG"] = (vig_image.path.name, "C3 vignetting calibration file")

    ramp = np.zeros_like(data, dtype=np.float64)
    if _compact(header.get("FILTER")) == "CLEAR":
        ramp_image = c3_ramp(config)
        ramp = crop_to_lasco_roi(ramp_image.data, header)
        ramp = apply_summing_to_calibration(ramp, header)
        header["C3RAMP"] = (ramp_image.path.name, "C3 ramp calibration file")

    mask = np.ones_like(data, dtype=np.float64)
    if config.apply_mask:
        mask_image = c3_mask(config)
        mask = crop_to_lasco_roi(mask_image.data, header)
        mask = apply_summing_to_calibration(mask, header)
        header["C3MASK"] = (mask_image.path.name, "C3 mask calibration file")

    if _compact(header.get("POLAR")) in POLARIZATION_PRODUCTS:
        calibrated = data * calfac * vig / exptime
    else:
        calibrated = (data - bias) * vig * calfac / exptime - ramp
    calibrated = calibrated * mask

    header["EXPTIME"] = (exptime, "Corrected exposure time (seconds)")
    header["CALFAC"] = (calfac, "Conversion from DN to MSB")
    header["EXPFAC"] = (expfac, "Exposure time correction factor")
    header["OFFSET"] = (bias, "Corrected CCD offset bias")
    return calibrated
