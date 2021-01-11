// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../TornadoProxy.sol";

contract TornadoProxyMock is TornadoProxy {
  uint256 public timestamp;
  uint256 public currentBlock;

  constructor(
    bytes32 _tornadoTrees,
    bytes32 _governance,
    Instance[] memory _instances
  ) public TornadoProxy(_tornadoTrees, _governance, _instances) {}

  function resolve(bytes32 _addr) public view override returns (address) {
    return address(uint160(uint256(_addr) >> (12 * 8)));
  }
}
