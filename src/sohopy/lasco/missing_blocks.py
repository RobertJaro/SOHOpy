"""Missing telemetry block helpers for LASCO images."""

from __future__ import annotations

import numpy as np

BASE32_ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUV"


def int_to_b32(value: int, digits: int | None = None) -> str:
    """Convert an integer to the legacy LASCO base-32 representation."""

    if value < 0:
        raise ValueError("LASCO base-32 values must be non-negative.")
    if value == 0:
        text = "0"
    else:
        chars: list[str] = []
        while value:
            value, rem = divmod(value, 32)
            chars.append(BASE32_ALPHABET[rem])
        text = "".join(reversed(chars))
    if digits is None:
        return text
    if len(text) > digits:
        return "*" * digits
    return text.rjust(digits, "0")


def b32_to_int(value: str) -> int:
    """Convert a legacy LASCO base-32 string to an integer."""

    total = 0
    for char in value.strip().upper():
        total = total * 32 + BASE32_ALPHABET.index(char)
    return total


def missing_block_mask(image: np.ndarray, block_size: int = 32) -> np.ndarray:
    """Return a block mask with 0 for all-zero telemetry blocks."""

    data = np.asarray(image)
    ny, nx = data.shape
    if ny % block_size or nx % block_size:
        raise ValueError("Image dimensions must be divisible by the block size.")
    blocks = data.reshape(ny // block_size, block_size, nx // block_size, block_size)
    return (blocks.mean(axis=(1, 3)) > 0).astype(np.uint8)


def missing_block_numbers(
    image: np.ndarray,
    *,
    r1col: int = 20,
    r1row: int = 1,
    r2col: int | None = None,
    r2row: int | None = None,
    colsum: int = 1,
    rowsum: int = 1,
    lebxsum: int = 1,
    lebysum: int = 1,
) -> np.ndarray:
    """Return absolute LASCO telemetry block numbers like `miss_blocks.pro`."""

    data = np.asarray(image)
    if data.ndim != 2:
        raise ValueError("LASCO missing-block detection expects a 2D image.")
    ny, nx = data.shape
    r2col = r2col if r2col is not None else r1col + nx - 1
    r2row = r2row if r2row is not None else r1row + ny - 1
    xsum = max(colsum, 1) * max(lebxsum, 1)
    ysum = max(rowsum, 1) * max(lebysum, 1)
    nxpixblk = 32 // xsum
    nypixblk = 32 // ysum
    if nxpixblk <= 0 or nypixblk <= 0:
        raise ValueError("Summing parameters imply sub-pixel telemetry blocks.")
    if nx % nxpixblk or ny % nypixblk:
        raise ValueError("Image shape is not compatible with telemetry block size.")

    blocks = data.reshape(ny // nypixblk, nypixblk, nx // nxpixblk, nxpixblk)
    block_mask = (blocks.mean(axis=(1, 3)) > 0).astype(np.uint8)
    start_xblock = (r1col - 20) // 32
    start_yblock = (r1row - 1) // 32
    missing_y, missing_x = np.nonzero(block_mask == 0)
    if missing_x.size == 0:
        return np.array([-1], dtype=np.int64)
    del r2col, r2row
    return ((missing_y + start_yblock) * 32 + (missing_x + start_xblock)).astype(
        np.int64
    )


def missing_block_numbers_from_header(image: np.ndarray, header) -> np.ndarray:
    """Header-based wrapper for `missing_block_numbers`."""

    return missing_block_numbers(
        image,
        r1col=int(header.get("R1COL", 20)),
        r1row=int(header.get("R1ROW", 1)),
        r2col=int(header.get("R2COL", 0) or 0) or None,
        r2row=int(header.get("R2ROW", 0) or 0) or None,
        colsum=int(header.get("COLSUM", header.get("SUMCOL", 1)) or 1),
        rowsum=int(header.get("ROWSUM", header.get("SUMROW", 1)) or 1),
        lebxsum=int(header.get("LEBXSUM", 1) or 1),
        lebysum=int(header.get("LEBYSUM", 1) or 1),
    )


def mb_to_string_map(mask: np.ndarray) -> str:
    """Convert a missing-block mask to the compact legacy string map."""

    flat = np.rot90(np.asarray(mask), -1).ravel()
    missing = np.flatnonzero(flat == 0)
    if missing.size == 0:
        return ""

    runs: list[int] = [int(missing[0])]
    for prev, cur in zip(missing[:-1], missing[1:], strict=False):
        if cur != prev + 1:
            runs.extend([int(prev + 1), int(cur)])
    runs.append(int(missing[-1]))
    return "".join(int_to_b32(value, 2) for value in runs)


def string_map_to_mb(value: str, nx: int, ny: int, block_size: int = 32) -> np.ndarray:
    """Decode a LASCO missing-block string map into a block mask."""

    text = value.strip()
    mask = np.ones((ny // block_size, nx // block_size), dtype=np.uint8)
    if not text:
        return mask
    if len(text) % 2:
        raise ValueError("Missing-block string maps must contain pairs of chars.")

    positions = [b32_to_int(text[i : i + 2]) for i in range(0, len(text), 2)]
    if positions:
        positions[-1] += 1
    flat = np.rot90(mask, -1).ravel()
    for start, stop in zip(positions[0::2], positions[1::2], strict=False):
        flat[start:stop] = 0
    return np.rot90(flat.reshape(mask.T.shape), 1)
