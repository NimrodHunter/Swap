// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Return type of the beforeSwap hook.
// Upper 128 bits is the diference in specified tokens. Lower 128 bits is difference in unspecified tokens (to match the afterSwap hook)
type BeforeSwapDiff is int256;

// Creates a BeforeSwapDiff from specified and unspecified
function toBeforeSwapDiff(int128 diffSpecified, int128 diffUnspecified) pure returns (BeforeSwapDiff beforeSwapDiff) {
    assembly ("memory-safe") {
        beforeSwapDiff := or(shl(128, diffSpecified), and(sub(shl(128, 1), 1), diffUnspecified))
    }
}

/// @notice Library for getting the specified and unspecified differences from the BeforeSwapDiff type
library BeforeSwapDiffLibrary {
    /// @notice A BeforeSwapDiff of 0
    BeforeSwapDiff public constant ZERO_DIFF = BeforeSwapDiff.wrap(0);

    /// extracts int128 from the upper 128 bits of the BeforeSwapDiff
    /// returned by beforeSwap
    function getSpecifiedDelta(BeforeSwapDiff diff) internal pure returns (int128 diffSpecified) {
        assembly ("memory-safe") {
            diffSpecified := sar(128, diff)
        }
    }

    /// extracts int128 from the lower 128 bits of the BeforeSwapDiff
    /// returned by beforeSwap and afterSwap
    function getUnspecifiedDelta(BeforeSwapDiff diff) internal pure returns (int128 diffUnspecified) {
        assembly ("memory-safe") {
            diffUnspecified := signextend(15, diff)
        }
    }
}
