"""Configuration objects for LASCO data preparation."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Protocol

from astropy.io import fits


class ExposureCorrectionProvider(Protocol):
    """Callable that returns `(exposure_factor, bias)` for a LASCO header."""

    def __call__(self, header: fits.Header) -> tuple[float, float]: ...


@dataclass(frozen=True, slots=True)
class LASCOConfig:
    """Runtime configuration for LASCO processing.

    The IDL pipeline relies heavily on process-wide common blocks and environment
    variables such as LASCO_DATA. The Python port keeps those choices explicit so
    batch reductions are reproducible.
    """

    calibration_root: Path | str
    apply_vignetting: bool = True
    apply_mask: bool = True
    apply_distortion: bool = False
    correct_time: bool = False
    correct_roll: bool = False
    fill_missing_blocks: bool = False
    exposure_correction: ExposureCorrectionProvider | None = None

    def __post_init__(self) -> None:
        object.__setattr__(self, "calibration_root", Path(self.calibration_root))

    @property
    def calib_dir(self) -> Path:
        """Directory containing LASCO calibration FITS and table assets."""

        return Path(self.calibration_root)
