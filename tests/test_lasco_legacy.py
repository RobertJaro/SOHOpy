import math

import numpy as np
from astropy.io import fits
from astropy.time import Time

from sohopy.lasco.legacy import (
    check_obe_summing_error,
    dark_bias_statistics,
    telescope_configuration,
)
from sohopy.lasco.missing_blocks import (
    missing_block_numbers,
    missing_block_numbers_from_header,
)
from sohopy.lasco.statistics import add_level05_statistics, standard_intensity_scale
from sohopy.lasco.time import compare_cds_time, ddis_time_to_ecs


def test_ddis_time_to_ecs_accepts_two_and_four_digit_years() -> None:
    assert ddis_time_to_ecs("970307_010203") == "97/03/07 01:02:03"
    assert ddis_time_to_ecs("19970307_010203") == "1997/03/07 01:02:03"


def test_compare_cds_time_uses_legacy_sign_convention() -> None:
    t1 = Time("2000-01-01T00:00:00")
    t2 = Time("2000-01-02T00:00:00")

    assert compare_cds_time(t1, t2) == 1
    assert compare_cds_time(t2, t1) == -1
    assert compare_cds_time(t1, t1) == 0


def test_standard_intensity_scale_uses_bias_summing_and_exptime() -> None:
    header = fits.Header()
    header["OFFSET"] = 2
    header["LEBXSUM"] = 2
    header["LEBYSUM"] = 1
    header["SUMCOL"] = 2
    header["SUMROW"] = 1
    header["EXPTIME"] = 5

    scaled = standard_intensity_scale(np.array([[24.0]]), header)

    assert scaled[0, 0] == 1.0


def test_level05_statistics_adds_expected_keywords() -> None:
    header = add_level05_statistics(
        np.array([[0, 1, 2], [3, 16383, 5]], dtype=np.int64),
        fits.Header(),
    )

    assert header["DATAMIN"] == 1
    assert header["DATAMAX"] == 5
    assert header["DATAZER"] == 1
    assert header["DATASAT"] > 0


def test_check_obe_summing_error_can_repair_header() -> None:
    header = fits.Header()
    header["R1COL"] = 1
    header["R2COL"] = 64
    header["R1ROW"] = 1
    header["R2ROW"] = 64
    header["LEBXSUM"] = 1
    header["LEBYSUM"] = 1
    header["SUMCOL"] = 1
    header["SUMROW"] = 1

    check, fixed = check_obe_summing_error(np.ones((32, 32)), header, fix=True)

    assert check.mismatch
    assert check.factor_x == 2
    assert check.factor_y == 2
    assert fixed["LEBXSUM"] == 2
    assert fixed["LEBYSUM"] == 2


def test_telescope_configuration_corrects_legacy_readport_bug() -> None:
    header = fits.Header()
    header["FILTER"] = 2
    header["POLAR"] = 1
    header["DOOR"] = 0
    header["LAMP"] = 1
    header["SUMCOL"] = 2
    header["SUMROW"] = 3
    header["READPORT"] = "C"
    header["CLRMODE"] = 1

    assert telescope_configuration(header) == 200 * (2 + 18 + 72 + 144) + 57


def test_dark_bias_statistics_ignores_zero_pixels() -> None:
    stats = dark_bias_statistics(np.array([0.0, 10.0, 12.0, 14.0]), offset_bias=5)

    assert stats["median"] == 12
    assert stats["offset_bias"] == 5
    assert math.isfinite(stats["mean"])


def test_absolute_missing_block_numbers_with_header() -> None:
    image = np.ones((64, 64))
    image[:32, :32] = 0
    header = fits.Header()
    header["R1COL"] = 20
    header["R1ROW"] = 1
    header["SUMCOL"] = 1
    header["SUMROW"] = 1
    header["LEBXSUM"] = 1
    header["LEBYSUM"] = 1

    np.testing.assert_array_equal(missing_block_numbers(image), np.array([0]))
    np.testing.assert_array_equal(
        missing_block_numbers_from_header(image, header),
        np.array([0]),
    )
