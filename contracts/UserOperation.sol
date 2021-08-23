// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

    struct UserOperation {

        address target;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        uint64 callGas;
        uint verificationGas;
        uint64 maxFeePerGas;
        uint64 maxPriorityFeePerGas;
        address paymaster;
        bytes paymasterData;
        address signer;
        bytes signature;
    }

library UserOperationLib {

    //relayer/miner might submit the TX with higher priorityFee, but the user should not
    // pay above what he signed for.
    function gasPrice(UserOperation calldata userOp) internal view returns (uint) {
        return min(userOp.maxFeePerGas, min(userOp.maxPriorityFeePerGas + block.basefee, tx.gasprice));
    }

    function requiredPreFund(UserOperation calldata userOp) internal pure returns (uint prefund) {
        //NOTE: verificationGas should include cost of create: create2gas = 32000 + 200 * userOp.callData.length;
        return (userOp.callGas + userOp.verificationGas) * userOp.maxFeePerGas;
    }

    function pack(UserOperation calldata userOp) internal pure returns (bytes memory) {
        //TODO: eip712-style ?
        return abi.encode(
            userOp.target,
            userOp.nonce,
            keccak256(userOp.initCode),
            keccak256(userOp.callData),
            userOp.callGas,
            userOp.verificationGas,
            userOp.maxFeePerGas,
            userOp.maxPriorityFeePerGas,
            userOp.paymaster,
            keccak256(userOp.paymasterData)
        );
    }

    function hash(UserOperation calldata userOp) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",
            keccak256(pack(userOp))));
    }

    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
}
