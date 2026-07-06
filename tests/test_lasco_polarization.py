import math

import numpy as np
from astropy.io import fits

from sohopy.lasco.polarization import (
    combine_polarizer_triplet,
    combine_polarizer_triplet_files,
    write_polarization_products,
)


def _ideal_measurements(total: float, q: float, u: float) -> tuple[float, float, float]:
    minus_60 = 0.5 * (total - 0.5 * q - math.sqrt(3.0) / 2.0 * u)
    zero = 0.5 * (total + q)
    plus_60 = 0.5 * (total - 0.5 * q + math.sqrt(3.0) / 2.0 * u)
    return minus_60, zero, plus_60


def test_combine_polarizer_triplet_recovers_stokes_products() -> None:
    minus_60, zero, plus_60 = _ideal_measurements(total=12.0, q=3.0, u=4.0)

    result = combine_polarizer_triplet(
        np.array([[minus_60]]),
        np.array([[zero]]),
        np.array([[plus_60]]),
    )

    assert np.isclose(result.tB[0, 0], 12.0)
    assert np.isclose(result.stokes_q[0, 0], 3.0)
    assert np.isclose(result.stokes_u[0, 0], 4.0)
    assert np.isclose(result.pB[0, 0], 5.0)
    assert np.isclose(result.percent_polarization[0, 0], 100.0 * 5.0 / 12.0)


def test_polarization_file_api_and_writer(tmp_path) -> None:
    minus_60, zero, plus_60 = _ideal_measurements(total=9.0, q=0.0, u=0.0)
    header = fits.Header({"DETECTOR": "C2", "POLAR": "-60DEG", "BUNIT": "MSB"})
    minus_path = tmp_path / "minus.fts"
    zero_path = tmp_path / "zero.fts"
    plus_path = tmp_path / "plus.fts"
    fits.PrimaryHDU(np.full((2, 2), minus_60), header=header).writeto(minus_path)
    fits.PrimaryHDU(np.full((2, 2), zero), header=header).writeto(zero_path)
    fits.PrimaryHDU(np.full((2, 2), plus_60), header=header).writeto(plus_path)

    result = combine_polarizer_triplet_files(minus_path, zero_path, plus_path)
    tb_path = tmp_path / "tb.fts"
    pb_path = tmp_path / "pb.fts"
    pct_path = tmp_path / "pct.fts"
    write_polarization_products(
        result,
        total_brightness_path=tb_path,
        polarized_brightness_path=pb_path,
        percent_polarization_path=pct_path,
    )

    with fits.open(tb_path) as hdul:
        assert hdul[0].header["POLAR"] == "TB"
    with fits.open(pb_path) as hdul:
        assert hdul[0].header["POLAR"] == "PB"
    with fits.open(pct_path) as hdul:
        assert hdul[0].header["POLAR"] == "%P"
