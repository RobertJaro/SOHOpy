"""Time helpers for LASCO metadata."""

from __future__ import annotations

from astropy.io import fits
from astropy.time import Time


def observation_time(header: fits.Header) -> Time:
    """Parse the best observation time available in a LASCO header."""

    value = header.get("DATE-OBS") or header.get("DATE_OBS")
    if value is None:
        date = header.get("DATEOBS") or header.get("DATE_OBS")
        clock = header.get("TIME-OBS") or header.get("TIME_OBS")
        if date is not None and clock is not None:
            value = f"{date}T{clock}"
    if value is None:
        raise ValueError("LASCO header does not contain DATE-OBS/DATE_OBS.")

    text = str(value).strip()
    if " " in text and "T" not in text:
        text = text.replace(" ", "T", 1)
    parts = text.split("T", 1)
    if parts:
        parts[0] = parts[0].replace("/", "-")
    if len(parts) == 2:
        parts[1] = parts[1].replace("/", ":")
    text = "T".join(parts)
    return Time(text, format="isot", scale="utc")


def observation_mjd(header: fits.Header) -> float:
    """Return the observation Modified Julian Date."""

    return float(observation_time(header).mjd)


def ddis_time_to_ecs(value: str) -> str:
    """Convert `YYMMDD_HHMMSS` or `YYYYMMDD_HHMMSS` like `ddistim2ecs.pro`."""

    date, clock = value.strip().split("_", 1)
    if len(date) not in {6, 8} or len(clock) < 6:
        raise ValueError(f"Invalid DDIS time string: {value!r}")
    year_width = 2 if len(date) == 6 else 4
    return (
        f"{date[:year_width]}/{date[year_width:year_width + 2]}/"
        f"{date[year_width + 2:year_width + 4]} "
        f"{clock[:2]}:{clock[2:4]}:{clock[4:6]}"
    )


def compare_cds_time(time1: Time, time2: Time) -> int:
    """Compare two times with the legacy `diff2time.pro` sign convention.

    Returns `1` when `time1 < time2`, `-1` when `time1 > time2`, and `0` when
    the two times are equal.
    """

    if time1 < time2:
        return 1
    if time1 > time2:
        return -1
    return 0
