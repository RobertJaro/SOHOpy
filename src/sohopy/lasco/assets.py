"""Calibration asset discovery, caching, and loading for LASCO."""

from __future__ import annotations

import shutil
from dataclasses import dataclass
from pathlib import Path
from tempfile import NamedTemporaryFile
from urllib.error import URLError
from urllib.parse import urljoin
from urllib.request import urlopen

import numpy as np
from astropy.io import fits

from .config import LASCOConfig
from .exceptions import CalibrationAssetError
from .time import observation_mjd

C3_INTERRUPTION_MJD = 51000.0

DEFAULT_CALIBRATION_BASE_URLS = (
    "https://soho.nascom.nasa.gov/solarsoft/soho/lasco/calib/",
    "https://soho.nascom.nasa.gov/solarsoft/soho/lasco/idl/reduce/",
)

REQUIRED_CALIBRATION_ASSETS = {
    "c2_vignetting": "c2vig_final.fts",
    "c3_vignetting_pre_interruption": "c3vig_preint_final.fts",
    "c3_vignetting_post_interruption": "c3vig_postint_final.fts",
    "c3_level1_mask": "c3_cl_mask_lvl1.fts",
    "c3_clear_ramp": "C3ramp.fts",
    "c3_fuzzy_background": "3m_clcl_all.fts",
}


@dataclass(frozen=True, slots=True)
class CalibrationImage:
    """A loaded calibration image and its source path."""

    data: np.ndarray
    path: Path
    header: fits.Header


@dataclass(frozen=True, slots=True)
class CalibrationAssetStatus:
    """Availability information for one LASCO calibration asset."""

    name: str
    filename: str
    path: Path
    exists: bool


def required_calibration_assets() -> dict[str, str]:
    """Return the canonical LASCO Level 1 calibration asset manifest."""

    return dict(REQUIRED_CALIBRATION_ASSETS)


def inspect_calibration_assets(
    calibration_root: str | Path,
) -> list[CalibrationAssetStatus]:
    """Return local availability for the required LASCO calibration assets."""

    root = Path(calibration_root)
    return [
        CalibrationAssetStatus(
            name=name,
            filename=filename,
            path=root / filename,
            exists=(root / filename).exists(),
        )
        for name, filename in REQUIRED_CALIBRATION_ASSETS.items()
    ]


def missing_calibration_assets(calibration_root: str | Path) -> list[str]:
    """Return required LASCO calibration filenames missing from a local root."""

    return [
        status.filename
        for status in inspect_calibration_assets(calibration_root)
        if not status.exists
    ]


def _download_one(
    filename: str,
    destination: Path,
    *,
    base_urls: tuple[str, ...],
    timeout: float,
    overwrite: bool,
    validate: bool,
) -> Path:
    if destination.exists() and not overwrite:
        if validate:
            validate_calibration_fits(destination)
        return destination

    destination.parent.mkdir(parents=True, exist_ok=True)
    errors: list[str] = []
    for base_url in base_urls:
        url = urljoin(base_url if base_url.endswith("/") else f"{base_url}/", filename)
        tmp_path: Path | None = None
        try:
            with urlopen(url, timeout=timeout) as response:
                with NamedTemporaryFile(
                    "wb",
                    delete=False,
                    dir=destination.parent,
                    prefix=f".{filename}.",
                    suffix=".tmp",
                ) as tmp:
                    shutil.copyfileobj(response, tmp)
                    tmp_path = Path(tmp.name)
            if validate:
                validate_calibration_fits(tmp_path)
            tmp_path.replace(destination)
            return destination
        except (OSError, URLError) as exc:
            if tmp_path is not None:
                tmp_path.unlink(missing_ok=True)
            errors.append(f"{url}: {exc}")

    joined = "\n".join(errors)
    raise CalibrationAssetError(
        f"Could not download LASCO calibration asset {filename!r}.\n{joined}"
    )


def ensure_calibration_assets(
    calibration_root: str | Path,
    *,
    filenames: list[str] | tuple[str, ...] | None = None,
    base_urls: tuple[str, ...] = DEFAULT_CALIBRATION_BASE_URLS,
    timeout: float = 30.0,
    overwrite: bool = False,
    validate: bool = True,
) -> dict[str, Path]:
    """Download missing LASCO calibration FITS assets into a local cache.

    Parameters
    ----------
    calibration_root:
        Directory that should contain the LASCO calibration FITS files.
    filenames:
        Optional subset of filenames to prepare. By default all required Level 1
        assets are prepared.
    base_urls:
        Public archive locations to try, in order. The default mirrors the
        modern SOHO/SolarSoft layout as closely as public HTTP access allows.
    timeout:
        Per-request timeout in seconds.
    overwrite:
        Replace existing files when true.
    validate:
        Open each prepared asset with Astropy FITS before accepting it.
    """

    root = Path(calibration_root)
    selected = tuple(filenames or REQUIRED_CALIBRATION_ASSETS.values())
    prepared: dict[str, Path] = {}
    for filename in selected:
        destination = root / filename
        prepared[filename] = _download_one(
            filename,
            destination,
            base_urls=base_urls,
            timeout=timeout,
            overwrite=overwrite,
            validate=validate,
        )
    return prepared


def validate_calibration_fits(path: str | Path) -> None:
    """Raise `CalibrationAssetError` if a calibration asset is not FITS image data."""

    try:
        with fits.open(path, memmap=False) as hdul:
            if hdul[0].data is None:
                raise CalibrationAssetError(
                    f"Calibration asset does not contain primary image data: {path}"
                )
    except CalibrationAssetError:
        raise
    except OSError as exc:
        raise CalibrationAssetError(
            f"Calibration asset is not a readable FITS file: {path}"
        ) from exc


def require_asset(config: LASCOConfig, filename: str) -> Path:
    """Return the path to a required calibration file."""

    path = config.calib_dir / filename
    if not path.exists():
        missing = ", ".join(missing_calibration_assets(config.calib_dir))
        raise CalibrationAssetError(
            f"Required LASCO calibration asset is missing: {path}. "
            f"Missing required assets under {config.calib_dir}: {missing or filename}"
        )
    return path


def read_calibration_image(config: LASCOConfig, filename: str) -> CalibrationImage:
    """Load a calibration FITS image from the configured calibration directory."""

    path = require_asset(config, filename)
    with fits.open(path, memmap=False) as hdul:
        data = np.asarray(hdul[0].data, dtype=np.float64)
        header = hdul[0].header.copy()
    return CalibrationImage(data=data, path=path, header=header)


def c2_vignetting(config: LASCOConfig) -> CalibrationImage:
    """Load the C2 vignetting correction used by the IDL pipeline."""

    image = read_calibration_image(config, "c2vig_final.fts")
    data = np.clip(image.data, 0.0, 100.0)
    return CalibrationImage(data=data, path=image.path, header=image.header)


def c3_vignetting(config: LASCOConfig, header: fits.Header) -> CalibrationImage:
    """Load the date-dependent C3 vignetting correction."""

    filename = (
        "c3vig_preint_final.fts"
        if observation_mjd(header) < C3_INTERRUPTION_MJD
        else "c3vig_postint_final.fts"
    )
    return read_calibration_image(config, filename)


def c3_mask(config: LASCOConfig) -> CalibrationImage:
    """Load the Level 1 C3 pylon/occulter mask."""

    return read_calibration_image(config, "c3_cl_mask_lvl1.fts")


def c3_ramp(config: LASCOConfig) -> CalibrationImage:
    """Load the C3 ramp correction image."""

    return read_calibration_image(config, "C3ramp.fts")


def c3_background(config: LASCOConfig) -> CalibrationImage:
    """Load the C3 background used by the legacy fuzzy-fill routine."""

    image = read_calibration_image(config, "3m_clcl_all.fts")
    exptime = float(image.header.get("EXPTIME", 1.0))
    return CalibrationImage(
        data=0.8 * image.data / exptime,
        path=image.path,
        header=image.header,
    )
