import math

from astropy.io import fits
from astropy.time import Time

from sohopy.lasco.calibration import c2_calibration_factor, c3_calibration_factor


def _header(detector: str, filter_name: str, polar: str = "CLEAR") -> fits.Header:
    header = fits.Header()
    header["DETECTOR"] = detector
    header["FILTER"] = filter_name
    header["POLAR"] = polar
    header["DATE-OBS"] = "2005-01-01T00:00:00.000"
    header["SUMCOL"] = 2
    header["SUMROW"] = 1
    header["LEBXSUM"] = 2
    header["LEBYSUM"] = 1
    return header


def test_c2_orange_time_dependent_factor_with_summing() -> None:
    header = _header("C2", "Orange")
    mjd = Time(header["DATE-OBS"], format="isot", scale="utc").mjd
    expected = (4.60403e-7 * mjd + 0.0374116) / 4 * 1e-10

    assert math.isclose(c2_calibration_factor(header), expected)


def test_c3_clear_time_dependent_factor_with_summing() -> None:
    header = _header("C3", "Clear")
    mjd = Time(header["DATE-OBS"], format="isot", scale="utc").mjd
    expected = (7.43e-8 * (mjd - 50000.0) + 5.96e-3) / 4 * 1e-10

    assert math.isclose(c3_calibration_factor(header), expected)


def test_c3_clear_halpha_polarizer_uses_legacy_constant() -> None:
    header = _header("C3", "Clear", "H_ALPHA")

    assert math.isclose(c3_calibration_factor(header, correct_summing=False), 1.541e-10)
