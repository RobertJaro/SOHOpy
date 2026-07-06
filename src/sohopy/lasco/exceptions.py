"""Exceptions raised by LASCO preparation code."""

from __future__ import annotations


class LASCOError(Exception):
    """Base class for LASCO processing errors."""


class CalibrationAssetError(LASCOError):
    """Raised when required calibration assets are missing or invalid."""


class UnsupportedReductionStepError(LASCOError):
    """Raised when a requested legacy step has not been ported yet."""
