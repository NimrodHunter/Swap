// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20Minimal} from "src/interfaces/external/IERC20Minimal.sol";
import {Revert} from "src/libraries/Revert.sol";

type Crypto is address;

using {greaterThan as >, lessThan as <, greaterThanOrEqualTo as >=, equals as ==} for Crypto global;
using CryptoLibrary for Crypto global;

function equals(Crypto crypto, Crypto other) pure returns (bool) {
    return Crypto.unwrap(crypto) == Crypto.unwrap(other);
}

function greaterThan(Crypto crypto, Crypto other) pure returns (bool) {
    return Crypto.unwrap(crypto) > Crypto.unwrap(other);
}

function lessThan(Crypto crypto, Crypto other) pure returns (bool) {
    return Crypto.unwrap(crypto) < Crypto.unwrap(other);
}

function greaterThanOrEqualTo(Crypto crypto, Crypto other) pure returns (bool) {
    return Crypto.unwrap(crypto) >= Crypto.unwrap(other);
}

/// @title CryptoLibrary
/// @dev This library allows for transferring and holding native tokens and ERC20 tokens
library CryptoLibrary {
    using Revert for bytes4;

    /// @notice Thrown when a native transfer fails
    /// @param revertReason bubbled up revert reason
    error NativeTransferFailed(bytes revertReason);

    /// @notice Thrown when an ERC20 transfer fails
    /// @param revertReason bubbled up revert reason
    error ERC20TransferFailed(bytes revertReason);

    /// @notice A constant to represent the native crypto
    Crypto public constant NATIVE = Crypto.wrap(address(0));

    function transfer(Crypto crypto, address to, uint256 amount) internal {
        // modified custom error selectors

        bool success;
        if (crypto.isNative()) {
            assembly ("memory-safe") {
                // Transfer the ETH and revert if it fails.
                success := call(gas(), to, amount, 0, 0, 0, 0)
            }
            // revert with NativeTransferFailed, containing the shoed up error as an argument
            if (!success) NativeTransferFailed.selector.showUpAndRevertWith();
        } else {
            assembly ("memory-safe") {
                // Get a pointer to some free memory.
                let fmp := mload(0x40)

                // Write the abi-encoded calldata into memory, beginning with the function selector.
                mstore(fmp, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
                mstore(add(fmp, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
                mstore(add(fmp, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

                success :=
                    and(
                        // Set success to whether the call reverted, if not we check it either
                        // returned exactly 1 (can't just be non-zero data), or had no return data.
                        or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                        // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                        // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                        // Counterintuitively, this call must be positioned second to the or() call in the
                        // surrounding and() call or else returndatasize() will be zero during the computation.
                        call(gas(), crypto, 0, fmp, 68, 0, 32)
                    )

                // Now clean the memory we used
                mstore(fmp, 0) // 4 byte `selector` and 28 bytes of `to` were stored here
                mstore(add(fmp, 0x20), 0) // 4 bytes of `to` and 28 bytes of `amount` were stored here
                mstore(add(fmp, 0x40), 0) // 4 bytes of `amount` were stored here
            }
            // revert with ERC20TransferFailed, containing the bubbled up error as an argument
            if (!success) ERC20TransferFailed.selector.showUpAndRevertWith();
        }
    }

    function balanceOfSelf(Crypto crypto) internal view returns (uint256) {
        if (crypto.isNative()) {
            return address(this).balance;
        } else {
            return IERC20Minimal(Crypto.unwrap(crypto)).balanceOf(address(this));
        }
    }

    function balanceOf(Crypto crypto, address owner) internal view returns (uint256) {
        if (crypto.isNative()) {
            return owner.balance;
        } else {
            return IERC20Minimal(Crypto.unwrap(crypto)).balanceOf(owner);
        }
    }

    function isNative(Crypto crypto) internal pure returns (bool) {
        return Crypto.unwrap(crypto) == Crypto.unwrap(NATIVE);
    }

    function isZero(Crypto crypto) internal pure returns (bool) {
        return isNative(crypto);
    }

    function toId(Crypto crypto) internal pure returns (uint256) {
        return uint160(Crypto.unwrap(crypto));
    }

    // If the upper 12 bytes are non-zero, they will be zero-ed out
    // Therefore, fromId() and toId() are not inverses of each other
    function fromId(uint256 id) internal pure returns (Crypto) {
        return Crypto.wrap(address(uint160(id)));
    }
}
