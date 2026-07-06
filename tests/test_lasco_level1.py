import numpy as np
from astropy.io import fits

from sohopy.lasco import LASCOConfig, reduce_level_1


def test_reduce_level_1_runs_c2_synthetic_product(tmp_path) -> None:
    input_path = tmp_path / "c2_l05.fts"
    output_path = tmp_path / "c2_l1.fts"
    fits.PrimaryHDU(
        data=np.full((64, 64), 10.0),
        header=fits.Header(
            {
                "DETECTOR": "C2",
                "FILTER": "Orange",
                "POLAR": "CLEAR",
                "DATE-OBS": "2005-01-01T00:00:00.000",
                "EXPTIME": 2.0,
                "OFFSET": 1.0,
                "SUMCOL": 1,
                "SUMROW": 1,
                "LEBXSUM": 1,
                "LEBYSUM": 1,
            }
        ),
    ).writeto(input_path)
    fits.PrimaryHDU(data=np.ones((64, 64))).writeto(tmp_path / "c2vig_final.fts")

    result = reduce_level_1(
        input_path,
        config=LASCOConfig(calibration_root=tmp_path),
        output_path=output_path,
    )

    assert output_path.exists()
    assert result.header["LEVEL"] == "1.0"
    assert result.header["BUNIT"] == "MSB"
    assert result.header["NMISSING"] == 0
    assert result.header["C2VIG"] == "c2vig_final.fts"
    assert np.all(result.image > 0)
