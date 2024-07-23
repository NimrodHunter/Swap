// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {SafeCast} from "src/libraries/SafeCast.sol";

/// @dev Two `int128` values packed into a single `int256` where the upper 128 bits represent the amount0
/// and the lower 128 bits represent the amount1.
type BalanceDiff is int256;

using {add as +, sub as -, eq as ==, neq as !=} for BalanceDiff global;
using BalanceDiffLibrary for BalanceDiff global;
using SafeCast for int256;

function getBalanceDiff(int128 _amount0, int128 _amount1) pure returns (BalanceDiff balanceDiff) {
    assembly ("memory-safe") {
        balanceDiff := or(shl(128, _amount0), and(sub(shl(128, 1), 1), _amount1))
    }
}

function add(BalanceDiff a, BalanceDiff b) pure returns (BalanceDiff) {
    int256 res0;
    int256 res1;
    assembly ("memory-safe") {
        let a0 := sar(128, a)
        let a1 := signextend(15, a)
        let b0 := sar(128, b)
        let b1 := signextend(15, b)
        res0 := add(a0, b0)
        res1 := add(a1, b1)
    }
    return getBalanceDiff(res0.toInt128(), res1.toInt128());
}

function sub(BalanceDiff a, BalanceDiff b) pure returns (BalanceDiff) {
    int256 res0;
    int256 res1;
    assembly ("memory-safe") {
        let a0 := sar(128, a)
        let a1 := signextend(15, a)
        let b0 := sar(128, b)
        let b1 := signextend(15, b)
        res0 := sub(a0, b0)
        res1 := sub(a1, b1)
    }
    return getBalanceDiff(res0.toInt128(), res1.toInt128());
}

function eq(BalanceDiff a, BalanceDiff b) pure returns (bool) {
    return BalanceDiff.unwrap(a) == BalanceDiff.unwrap(b);
}

function neq(BalanceDiff a, BalanceDiff b) pure returns (bool) {
    return BalanceDiff.unwrap(a) != BalanceDiff.unwrap(b);
}

/// @notice Library for getting the amount0 and amount1 difference from the BalanceDiff type
library BalanceDiffLibrary {
    /// @notice A BalanceDiff of 0
    BalanceDiff public constant ZERO_DIFF = BalanceDiff.wrap(0);

    function amount0(BalanceDiff balanceDiff) internal pure returns (int128 _amount0) {
        assembly ("memory-safe") {
            _amount0 := sar(128, balanceDiff)
        }
    }

    function amount1(BalanceDiff balanceDiff) internal pure returns (int128 _amount1) {
        assembly ("memory-safe") {
            _amount1 := signextend(15, balanceDiff)
        }
    }
}
