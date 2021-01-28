// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../TornadoTrees.sol";

contract TornadoTreesMock is TornadoTrees {
  uint256 public timestamp;
  uint256 public currentBlock;

  constructor(
    bytes32 _governance,
    bytes32 _tornadoProxy,
    bytes32 _treeUpdateVerifier,
    bytes32 _depositRoot,
    bytes32 _withdrawalRoot
  ) public TornadoTrees(_governance, _tornadoProxy, _treeUpdateVerifier, _depositRoot, _withdrawalRoot) {}

  function resolve(bytes32 _addr) public view override returns (address) {
    return address(uint160(uint256(_addr) >> (12 * 8)));
  }

  function setBlockNumber(uint256 _blockNumber) public {
    currentBlock = _blockNumber;
  }

  function blockNumber() public view override returns (uint256) {
    return currentBlock == 0 ? block.number : currentBlock;
  }

  function register(
    address _instance,
    bytes32 _commitment,
    bytes32 _nullifier,
    uint256 _depositBlockNumber,
    uint256 _withdrawBlockNumber
  ) public {
    setBlockNumber(_depositBlockNumber);
    deposits.push(keccak256(abi.encode(_instance, _commitment, blockNumber())));
    setBlockNumber(_withdrawBlockNumber);
    withdrawals.push(keccak256(abi.encode(_instance, _nullifier, blockNumber())));
  }
}
