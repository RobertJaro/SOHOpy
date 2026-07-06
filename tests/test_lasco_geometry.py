import numpy as np
from astropy.io import fits

from sohopy.lasco.geometry import rectify_p1p2, reduce_rectify
from sohopy.lasco.image_ops import make_browse_image


def _rectify_header() -> fits.Header:
    header = fits.Header()
    header["P1COL"] = 20
    header["P2COL"] = 83
    header["P1ROW"] = 1
    header["P2ROW"] = 64
    header["NAXIS1"] = 64
    header["NAXIS2"] = 32
    header["DETECTOR"] = "C2"
    return header


def test_rectify_p1p2_port_b_matches_idl_formula() -> None:
    header = rectify_p1p2(_rectify_header(), "B")

    assert header["R1COL"] == 20
    assert header["R2COL"] == 83
    assert header["R1ROW"] == 1
    assert header["R2ROW"] == 64
    assert header["EFFPORT"] == "B"


def test_reduce_rectify_updates_axes_for_non_c1_ports() -> None:
    header = _rectify_header()
    header["READPORT"] = "D"
    image = np.arange(6).reshape(2, 3)

    rectified, out = reduce_rectify(image, header)

    assert rectified.shape == (3, 2)
    assert out["NAXIS1"] == 32
    assert out["NAXIS2"] == 64
    assert out["RECTIFY"] == "TRUE"


def test_make_browse_image_preserves_aspect_and_scales_to_uint8() -> None:
    browse = make_browse_image(np.arange(100).reshape(10, 10), maxpix=5)

    assert browse.shape == (5, 5)
    assert browse.dtype == np.uint8
