from pathlib import Path

import numpy as np
from astropy.io import fits

from sohopy.lasco import (
    CalibrationAssetError,
    ensure_calibration_assets,
    inspect_calibration_assets,
    missing_calibration_assets,
    required_calibration_assets,
)
from sohopy.lasco.cli import calibration_main


def _write_asset(root: Path, filename: str) -> None:
    fits.PrimaryHDU(data=np.ones((4, 4), dtype=np.float32)).writeto(root / filename)


def test_inspect_calibration_assets_reports_missing_and_present(tmp_path) -> None:
    filename = required_calibration_assets()["c2_vignetting"]
    _write_asset(tmp_path, filename)

    statuses = inspect_calibration_assets(tmp_path)
    by_filename = {status.filename: status for status in statuses}

    assert by_filename[filename].exists
    assert "c3vig_preint_final.fts" in missing_calibration_assets(tmp_path)


def test_ensure_calibration_assets_downloads_from_file_url(tmp_path) -> None:
    source = tmp_path / "source"
    cache = tmp_path / "cache"
    source.mkdir()
    filename = "c2vig_final.fts"
    _write_asset(source, filename)

    prepared = ensure_calibration_assets(
        cache,
        filenames=[filename],
        base_urls=(source.as_uri(),),
    )

    assert prepared[filename] == cache / filename
    with fits.open(cache / filename, memmap=False) as hdul:
        assert hdul[0].data.shape == (4, 4)


def test_ensure_calibration_assets_rejects_non_fits_download(tmp_path) -> None:
    source = tmp_path / "source"
    cache = tmp_path / "cache"
    source.mkdir()
    filename = "c2vig_final.fts"
    (source / filename).write_text("not a fits file")

    try:
        ensure_calibration_assets(
            cache,
            filenames=[filename],
            base_urls=(source.as_uri(),),
        )
    except CalibrationAssetError as exc:
        assert "not a readable FITS" in str(exc)
    else:  # pragma: no cover
        raise AssertionError("Expected invalid calibration asset to be rejected.")

    assert not (cache / filename).exists()


def test_calibration_cli_lists_assets_and_returns_failure_for_missing(
    tmp_path,
    capsys,
) -> None:
    result = calibration_main([str(tmp_path)])
    captured = capsys.readouterr()

    assert result == 1
    assert "missing c2vig_final.fts" in captured.out
