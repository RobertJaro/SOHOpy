import numpy as np

from sohopy.lasco.missing_blocks import (
    b32_to_int,
    int_to_b32,
    mb_to_string_map,
    missing_block_mask,
    string_map_to_mb,
)


def test_base32_roundtrip() -> None:
    for value in [0, 1, 9, 10, 31, 32, 1023]:
        assert b32_to_int(int_to_b32(value)) == value


def test_missing_block_string_map_roundtrip() -> None:
    image = np.ones((64, 64))
    image[:32, :32] = 0
    image[32:, 32:] = 0

    mask = missing_block_mask(image)
    text = mb_to_string_map(mask)

    assert text
    np.testing.assert_array_equal(string_map_to_mb(text, 64, 64), mask)
