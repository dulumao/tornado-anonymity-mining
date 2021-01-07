// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "torn-token/contracts/ENS.sol";
import "./interfaces/ITornadoTrees.sol";
import "./interfaces/IVerifier.sol";

contract TornadoTrees is ITornadoTrees, EnsResolve {
  bytes32 public depositRoot;
  bytes32 public withdrawalRoot;
  address public immutable tornadoProxy;
  IVerifier public immutable treeUpdateVerifier;

  uint256 public constant CHUNK_SIZE = 128;

  bytes32[] public deposits;
  uint256 public lastProcessedDepositLeaf;

  bytes32[] public withdrawals;
  uint256 public lastProcessedWithdrawalLeaf;

  event DepositData(address instance, bytes32 indexed hash, uint256 block, uint256 index);
  event WithdrawalData(address instance, bytes32 indexed hash, uint256 block, uint256 index);

  struct TreeLeaf {
    address instance;
    bytes32 hash;
    uint256 block;
  }

  modifier onlyTornadoProxy {
    require(msg.sender == tornadoProxy, "Not authorized");
    _;
  }

  constructor(
    bytes32 _tornadoProxy,
    bytes32 _treeUpdateVerifier,
    bytes32 _depositRoot,
    bytes32 _withdrawalRoot
  ) public {
    tornadoProxy = resolve(_tornadoProxy);
    treeUpdateVerifier = IVerifier(resolve(_treeUpdateVerifier));
    depositRoot = _depositRoot;
    withdrawalRoot = _withdrawalRoot;
  }

  function registerDeposit(address _instance, bytes32 _commitment) external override onlyTornadoProxy {
    deposits.push(keccak256(abi.encode(_instance, _commitment, blockNumber())));
  }

  function registerWithdrawal(address _instance, bytes32 _nullifier) external override onlyTornadoProxy {
    withdrawals.push(keccak256(abi.encode(_instance, _nullifier, blockNumber())));
  }

  function updateRoots(
    bytes calldata _depositProof,
    bytes32 _previousDepositRoot,
    bytes32 _newDepositRoot,
    TreeLeaf[] calldata _deposits,
    bytes calldata _withdrawalProof,
    bytes32 _previousWithdrawalRoot,
    bytes32 _newWithdrawalRoot,
    TreeLeaf[] calldata _withdrawals
  ) external {
    if (_deposits.length > 0) {
      updateDepositTree(_depositProof, _previousDepositRoot, _newDepositRoot, _deposits);
    }
    if (_withdrawals.length > 0) {
      updateWithdrawalTree(_withdrawalProof, _previousWithdrawalRoot, _newWithdrawalRoot, _withdrawals);
    }
  }

  // todo !!! ensure that during migration the tree is filled evenly
  function updateDepositTree(
    bytes calldata _proof,
    bytes32 _previousRoot,
    bytes32 _newRoot,
    TreeLeaf[] calldata _events
  ) public {
    require(_events.length == CHUNK_SIZE, "Incorrect deposit array size");
    require(_previousRoot == depositRoot, "Incorrect deposit array size");

    uint256 offset = lastProcessedDepositLeaf;
    uint256[3 + 3 * CHUNK_SIZE] memory args;
    args[0] = lastProcessedDepositLeaf;
    args[1] = uint256(_previousRoot);
    args[2] = uint256(_newRoot);
    args[3] = 1; // todo index
    for (uint256 i = 0; i < CHUNK_SIZE; i++) {
      bytes32 leafHash = keccak256(abi.encode(_events[i].instance, _events[i].hash, _events[i].block));
      require(deposits[offset + i] == leafHash, "Incorrect deposit");
      args[3 + 3 * i] = uint256(_events[i].instance);
      args[4 + 3 * i] = uint256(_events[i].hash);
      args[5 + 3 * i] = uint256(_events[i].block);
      emit DepositData(_events[i].instance, _events[i].hash, _events[i].block, offset + i);
      delete deposits[offset + i];
    }

    treeUpdateVerifier.verifyProof(_proof, args);

    depositRoot = _newRoot;
    lastProcessedDepositLeaf = offset + CHUNK_SIZE;
  }

  function updateWithdrawalTree(
    bytes calldata _proof,
    bytes32 _previousRoot,
    bytes32 _newRoot,
    TreeLeaf[] calldata _events
  ) public {
    require(_events.length == CHUNK_SIZE, "Incorrect withdrawal array size");
    require(_previousRoot == withdrawalRoot, "Incorrect withdrawal array size");

    uint256 offset = lastProcessedWithdrawalLeaf;
    uint256[3 + 3 * CHUNK_SIZE] memory args;
    args[0] = lastProcessedWithdrawalLeaf;
    args[1] = uint256(_previousRoot);
    args[2] = uint256(_newRoot);
    args[3] = 1; // todo index
    for (uint256 i = 0; i < CHUNK_SIZE; i++) {
      bytes32 leafHash = keccak256(abi.encode(_events[i].instance, _events[i].hash, _events[i].block));
      require(withdrawals[offset + i] == leafHash, "Incorrect withdrawal");
      args[3 + 3 * i] = uint256(_events[i].instance);
      args[4 + 3 * i] = uint256(_events[i].hash);
      args[5 + 3 * i] = uint256(_events[i].block);
      emit WithdrawalData(_events[i].instance, _events[i].hash, _events[i].block, offset + i);
      delete withdrawals[offset + i];
    }

    treeUpdateVerifier.verifyProof(_proof, args);

    withdrawalRoot = _newRoot;
    lastProcessedWithdrawalLeaf = offset + CHUNK_SIZE;
  }

  function validateRoots(bytes32 _depositRoot, bytes32 _withdrawalRoot) public view {
    require(depositRoot == _depositRoot, "Incorrect deposit tree root");
    require(withdrawalRoot == _withdrawalRoot, "Incorrect withdrawal tree root");
  }

  function getRegisteredDeposits() external view returns (bytes32[] memory _deposits) {
    uint256 count = deposits.length - lastProcessedDepositLeaf;
    _deposits = new bytes32[](count);
    for (uint256 i = 0; i < count; i++) {
      _deposits[i] = deposits[lastProcessedDepositLeaf + i];
    }
  }

  function getRegisteredWithdrawals() external view returns (bytes32[] memory _withdrawals) {
    uint256 count = withdrawals.length - lastProcessedWithdrawalLeaf;
    _withdrawals = new bytes32[](count);
    for (uint256 i = 0; i < count; i++) {
      _withdrawals[i] = withdrawals[lastProcessedWithdrawalLeaf + i];
    }
  }

  function blockNumber() public view virtual returns (uint256) {
    return block.number;
  }
}
