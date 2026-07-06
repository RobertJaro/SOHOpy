import numpy as np
from astropy.io import fits

from sohopy.lasco.statistics import add_level1_statistics, scale_c3_clear_to_int16


def test_add_level1_statistics_ignores_zero_minimum() -> None:
    header = add_level1_statistics(np.array([[0.0, 1.0], [2.0, 3.0]]), fits.Header())

    assert header["DATAMIN"] == 1.0
    assert header["DATAMAX"] == 3.0
    assert header["DATAZER"] == 1
    assert header["DATAP50"] == 2.0


def test_scale_c3_clear_sets_fits_scaling_keywords() -> None:
    scaled, header = scale_c3_clear_to_int16(
        np.array([[0.0, 6.5e-9]]),
        fits.Header(),
    )

    assert scaled.dtype == np.int16
    assert scaled[0, 0] == 0
    assert header["BLANK"] == -32768
    assert header["BSCALE"] > 0
