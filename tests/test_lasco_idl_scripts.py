from pathlib import Path


def test_idl_parity_scripts_are_present() -> None:
    scripts = Path("scripts/idl")

    assert (scripts / "run_lasco_parity.pro").exists()
    assert (scripts / "run_lasco_parity.sh").exists()
