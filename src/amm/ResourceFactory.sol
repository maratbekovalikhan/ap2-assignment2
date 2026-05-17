// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ResourceToken} from "../core/ResourceToken.sol";
import {ResourcePair} from "./ResourcePair.sol";

contract ResourceFactory is AccessControl {
    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");

    uint256 public nextResourceId;
    mapping(uint256 resourceId => address token) public resourceById;
    mapping(address token => uint256 resourceId) public resourceIdOf;
    mapping(address token0 => mapping(address token1 => address pair)) public getPair;

    event ResourceDeployed(uint256 indexed resourceId, address indexed token, string name, string symbol);
    event PairDeployed(address indexed token0, address indexed token1, address pair, bytes32 salt);

    constructor(address admin) {
        require(admin != address(0), "admin=0");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(DEPLOYER_ROLE, admin);
    }

    function deployResource(
        string calldata name,
        string calldata symbol,
        address admin,
        address initialHolder,
        uint256 initialSupply
    ) external onlyRole(DEPLOYER_ROLE) returns (uint256 resourceId, address token) {
        token = address(new ResourceToken(name, symbol, admin, initialHolder, initialSupply));
        resourceId = ++nextResourceId;
        resourceById[resourceId] = token;
        resourceIdOf[token] = resourceId;

        emit ResourceDeployed(resourceId, token, name, symbol);
    }

    function deployPair(address tokenA, address tokenB) external onlyRole(DEPLOYER_ROLE) returns (address pair) {
        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        require(getPair[token0][token1] == address(0), "pair exists");

        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        pair = address(new ResourcePair{salt: salt}(token0, token1));
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;

        emit PairDeployed(token0, token1, pair, salt);
    }

    function predictPairAddress(address tokenA, address tokenB) external view returns (address predicted) {
        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        bytes memory bytecode = abi.encodePacked(type(ResourcePair).creationCode, abi.encode(token0, token1));
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));
        predicted = address(uint160(uint256(hash)));
    }

    function _sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != address(0) && tokenB != address(0) && tokenA != tokenB, "bad tokens");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }
}
