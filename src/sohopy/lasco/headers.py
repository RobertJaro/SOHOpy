"""Header normalization for LASCO FITS products."""

from __future__ import annotations

from astropy.io import fits


def normalize_lasco_header(header: fits.Header) -> fits.Header:
    """Return a normalized, mutable copy of a LASCO FITS header.

    The legacy code accepts both FITS headers and LASCO structures. Python will
    use FITS headers as the canonical interchange representation and normalize
    spelling differences at the boundary.
    """

    normalized = header.copy()
    detector = normalized.get("DETECTOR")
    if detector is not None:
        normalized["DETECTOR"] = str(detector).strip().upper()

    for key in ("FILTER", "POLAR", "READPORT"):
        value = normalized.get(key)
        if value is not None:
            normalized[key] = str(value).strip()

    return normalized
