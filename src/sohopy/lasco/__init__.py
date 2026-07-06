"""SOHO/LASCO data preparation API."""

from __future__ import annotations

from .assets import (
    CalibrationAssetStatus,
    ensure_calibration_assets,
    inspect_calibration_assets,
    missing_calibration_assets,
    required_calibration_assets,
)
from .config import LASCOConfig
from .exceptions import CalibrationAssetError, LASCOError, UnsupportedReductionStepError
from .level1 import Level1Result, reduce_level_1
from .polarization import (
    PolarizationResult,
    combine_polarizer_triplet,
    combine_polarizer_triplet_files,
    write_polarization_products,
)
from .visualization import (
    plot_fits_image,
    plot_lasco_image,
    plot_polarization_summary,
)

__all__ = [
    "CalibrationAssetError",
    "CalibrationAssetStatus",
    "LASCOConfig",
    "LASCOError",
    "Level1Result",
    "PolarizationResult",
    "UnsupportedReductionStepError",
    "combine_polarizer_triplet",
    "combine_polarizer_triplet_files",
    "ensure_calibration_assets",
    "inspect_calibration_assets",
    "missing_calibration_assets",
    "plot_fits_image",
    "plot_lasco_image",
    "plot_polarization_summary",
    "reduce_level_1",
    "required_calibration_assets",
    "write_polarization_products",
]
