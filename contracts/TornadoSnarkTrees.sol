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

  uint256 public constant CHUNK_TREE_HEIGHT = 7;
  uint256 public constant CHUNK_SIZE = 2**CHUNK_TREE_HEIGHT;

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
    uint256 _depositPathIndices,
    TreeLeaf[] calldata _deposits,
    bytes calldata _withdrawalProof,
    bytes32 _previousWithdrawalRoot,
    bytes32 _newWithdrawalRoot,
    uint256 _withdrawalPathIndices,
    TreeLeaf[] calldata _withdrawals
  ) external {
    if (_deposits.length > 0) {
      updateDepositTree(_depositProof, _previousDepositRoot, _newDepositRoot, _depositPathIndices, _deposits);
    }
    if (_withdrawals.length > 0) {
      updateWithdrawalTree(_withdrawalProof, _previousWithdrawalRoot, _newWithdrawalRoot, _withdrawalPathIndices, _withdrawals);
    }
  }

  // todo !!! ensure that during migration the tree is filled evenly
  function updateDepositTree(
    bytes calldata _proof,
    bytes32 _previousRoot,
    bytes32 _newRoot,
    uint256 _pathIndices,
    TreeLeaf[] calldata _events
  ) public {
    uint256 offset = lastProcessedDepositLeaf;
    require(_events.length == CHUNK_SIZE, "Incorrect deposit array size");
    require(_previousRoot == depositRoot, "Incorrect deposit array size");
    require(_pathIndices == offset >> CHUNK_TREE_HEIGHT, "Incorrect insert index");

    uint256[3 + 3 * CHUNK_SIZE] memory args;
    args[0] = uint256(_previousRoot);
    args[1] = uint256(_newRoot);
    args[2] = _pathIndices; // TODO
    for (uint256 i = 0; i < CHUNK_SIZE; i++) {
      bytes32 leafHash = keccak256(abi.encode(_events[i].instance, _events[i].hash, _events[i].block));
      require(deposits[offset + i] == leafHash, "Incorrect deposit");
      args[3 + 0 * CHUNK_SIZE + i] = uint256(_events[i].instance);
      args[3 + 1 * CHUNK_SIZE + i] = uint256(_events[i].hash);
      args[3 + 2 * CHUNK_SIZE + i] = uint256(_events[i].block);
      emit DepositData(_events[i].instance, _events[i].hash, _events[i].block, offset + i);
      delete deposits[offset + i];
    }

    require(treeUpdateVerifier.verifyProof(_proof, args), "Invalid deposit tree update proof");

    depositRoot = _newRoot;
    lastProcessedDepositLeaf = offset + CHUNK_SIZE;
  }

  function updateWithdrawalTree(
    bytes calldata _proof,
    bytes32 _previousRoot,
    bytes32 _newRoot,
    uint256 _pathIndices,
    TreeLeaf[] calldata _events
  ) public {
    uint256 offset = lastProcessedWithdrawalLeaf;
    require(_events.length == CHUNK_SIZE, "Incorrect withdrawal array size");
    require(_previousRoot == withdrawalRoot, "Incorrect withdrawal array size");
    require(_pathIndices == offset >> CHUNK_TREE_HEIGHT, "Incorrect insert index");

    uint256[3 + 3 * CHUNK_SIZE] memory args;
    args[0] = uint256(_previousRoot);
    args[1] = uint256(_newRoot);
    args[2] = lastProcessedWithdrawalLeaf >> CHUNK_TREE_HEIGHT; // TODO
    for (uint256 i = 0; i < CHUNK_SIZE; i++) {
      bytes32 leafHash = keccak256(abi.encode(_events[i].instance, _events[i].hash, _events[i].block));
      require(withdrawals[offset + i] == leafHash, "Incorrect withdrawal");
      args[3 + 0 * CHUNK_SIZE + i] = uint256(_events[i].instance);
      args[3 + 1 * CHUNK_SIZE + i] = uint256(_events[i].hash);
      args[3 + 2 * CHUNK_SIZE + i] = uint256(_events[i].block);
      emit WithdrawalData(_events[i].instance, _events[i].hash, _events[i].block, offset + i);
      delete withdrawals[offset + i];
    }

    require(treeUpdateVerifier.verifyProof(_proof, args), "Invalid withdrawal tree update proof");

    withdrawalRoot = _newRoot;
    lastProcessedWithdrawalLeaf = offset + CHUNK_SIZE;
  }

  // todo store previous root
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
