from pathlib import Path

from astropy.io import fits
from examples.lasco_full_workflow import run_workflow
from examples.lasco_level1_synthetic import run_example
from examples.lasco_polarization_synthetic import run_example as run_pol_example


def test_synthetic_lasco_example_runs(tmp_path: Path) -> None:
    output_path = run_example(tmp_path)

    assert output_path.exists()
    with fits.open(output_path) as hdul:
        assert hdul[0].header["LEVEL"] == "1.0"
        assert hdul[0].header["BUNIT"] == "MSB"
        assert hdul[0].header["NMISSING"] == 0


def test_synthetic_polarization_example_runs(tmp_path: Path) -> None:
    tb_path, pb_path = run_pol_example(tmp_path)

    assert tb_path.exists()
    assert pb_path.exists()
    with fits.open(tb_path) as hdul:
        assert hdul[0].header["POLAR"] == "TB"
    with fits.open(pb_path) as hdul:
        assert hdul[0].header["POLAR"] == "PB"


def test_full_workflow_writes_fits_and_png_products(tmp_path: Path) -> None:
    outputs = run_workflow(tmp_path)

    for key in ("level1", "tb", "pb", "level1_png", "polarization_png"):
        assert outputs[key].exists()
        assert outputs[key].stat().st_size > 0

    with fits.open(outputs["level1"]) as hdul:
        assert hdul[0].header["LEVEL"] == "1.0"
        assert hdul[0].header["C2VIG"] == "c2vig_final.fts"
