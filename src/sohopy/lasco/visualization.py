"""Visualization helpers for LASCO reduction products."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from astropy.io import fits


def _pyplot():
    try:
        import matplotlib.pyplot as plt
    except ImportError as exc:  # pragma: no cover - exercised by optional envs
        raise ImportError(
            "LASCO visualization helpers require matplotlib. Install with "
            '`python -m pip install "sohopy[viz]"`.'
        ) from exc
    return plt


def _scale_limits(
    image: np.ndarray,
    percentiles: tuple[float, float],
) -> tuple[float, float]:
    finite = np.asarray(image, dtype=np.float64)
    finite = finite[np.isfinite(finite)]
    if finite.size == 0:
        return 0.0, 1.0
    vmin, vmax = np.percentile(finite, percentiles)
    if not np.isfinite(vmin) or not np.isfinite(vmax) or vmin == vmax:
        center = float(np.nanmean(finite))
        return center - 0.5, center + 0.5
    return float(vmin), float(vmax)


def plot_lasco_image(
    image: np.ndarray,
    output_path: str | Path,
    *,
    header: fits.Header | None = None,
    title: str | None = None,
    percentiles: tuple[float, float] = (1.0, 99.0),
    cmap: str = "gray",
) -> Path:
    """Write a PNG preview for one LASCO image array."""

    data = np.asarray(image, dtype=np.float64)
    if data.ndim != 2:
        raise ValueError("LASCO image previews require a 2D array.")

    output = Path(output_path)
    output.parent.mkdir(parents=True, exist_ok=True)
    vmin, vmax = _scale_limits(data, percentiles)
    plt = _pyplot()
    fig, ax = plt.subplots(figsize=(6, 6), constrained_layout=True)
    im = ax.imshow(data, origin="lower", cmap=cmap, vmin=vmin, vmax=vmax)
    if title is None and header is not None:
        detector = str(header.get("DETECTOR", "LASCO")).strip()
        date_obs = str(header.get("DATE-OBS", "")).strip()
        title = f"{detector} {date_obs}".strip()
    if title:
        ax.set_title(title)
    ax.set_xlabel("X pixel")
    ax.set_ylabel("Y pixel")
    fig.colorbar(im, ax=ax, fraction=0.046, pad=0.04, label="MSB")
    fig.savefig(output, dpi=160)
    plt.close(fig)
    return output


def plot_fits_image(
    input_path: str | Path,
    output_path: str | Path,
    *,
    title: str | None = None,
    percentiles: tuple[float, float] = (1.0, 99.0),
    cmap: str = "gray",
) -> Path:
    """Write a PNG preview for a LASCO FITS image."""

    with fits.open(input_path, memmap=False) as hdul:
        data = np.asarray(hdul[0].data, dtype=np.float64)
        header = hdul[0].header.copy()
    return plot_lasco_image(
        data,
        output_path,
        header=header,
        title=title,
        percentiles=percentiles,
        cmap=cmap,
    )


def plot_polarization_summary(
    total_brightness: np.ndarray,
    polarized_brightness: np.ndarray,
    percent_polarization: np.ndarray,
    output_path: str | Path,
) -> Path:
    """Write a compact tB/pB/%p summary figure."""

    arrays = [
        np.asarray(total_brightness, dtype=np.float64),
        np.asarray(polarized_brightness, dtype=np.float64),
        np.asarray(percent_polarization, dtype=np.float64),
    ]
    if any(array.ndim != 2 for array in arrays):
        raise ValueError("Polarization summary inputs must be 2D arrays.")

    output = Path(output_path)
    output.parent.mkdir(parents=True, exist_ok=True)
    plt = _pyplot()
    fig, axes = plt.subplots(1, 3, figsize=(12, 4), constrained_layout=True)
    labels = ("tB [MSB]", "pB [MSB]", "% polarization")
    cmaps = ("gray", "magma", "viridis")
    for ax, array, label, cmap in zip(axes, arrays, labels, cmaps, strict=True):
        vmin, vmax = _scale_limits(array, (1.0, 99.0))
        im = ax.imshow(array, origin="lower", cmap=cmap, vmin=vmin, vmax=vmax)
        ax.set_title(label)
        ax.set_xticks([])
        ax.set_yticks([])
        fig.colorbar(im, ax=ax, fraction=0.046, pad=0.04)
    fig.savefig(output, dpi=160)
    plt.close(fig)
    return output
