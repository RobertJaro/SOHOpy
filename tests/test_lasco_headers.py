from astropy.io import fits

from sohopy.lasco.headers import normalize_lasco_header


def test_normalize_lasco_header_uppercases_detector() -> None:
    header = fits.Header()
    header["DETECTOR"] = " c3 "
    header["FILTER"] = " Clear "

    normalized = normalize_lasco_header(header)

    assert normalized["DETECTOR"] == "C3"
    assert normalized["FILTER"] == "Clear"
    assert header["DETECTOR"].strip() == "c3"
