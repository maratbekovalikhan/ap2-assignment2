// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ResourcePair is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant FEE_BPS = 30;
    uint256 public constant BPS_DENOMINATOR = 10_000;

    address public immutable token0;
    address public immutable token1;

    uint112 private _reserve0;
    uint112 private _reserve1;

    error InvalidToken();
    error InsufficientInput();
    error SlippageExceeded();
    error ZeroLiquidityMinted();
    error InsufficientLiquidityBurned();
    error InvalidRecipient();

    event LiquidityAdded(address indexed provider, uint256 amount0, uint256 amount1, uint256 liquidityMinted);
    event LiquidityRemoved(address indexed provider, uint256 amount0, uint256 amount1, uint256 liquidityBurned);
    event SwapExecuted(
        address indexed trader, address indexed tokenIn, uint256 amountIn, uint256 amountOut, address to
    );

    constructor(address token0_, address token1_) ERC20("LootForge LP", "LFLP") {
        require(token0_ != address(0) && token1_ != address(0) && token0_ != token1_, "bad tokens");
        token0 = token0_;
        token1 = token1_;
    }

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1) {
        return (_reserve0, _reserve1);
    }

    function addLiquidity(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external nonReentrant returns (uint256 liquidity) {
        if (to == address(0)) {
            revert InvalidRecipient();
        }

        IERC20(token0).safeTransferFrom(msg.sender, address(this), amount0Desired);
        IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1Desired);

        uint256 supply = totalSupply();
        if (supply == 0) {
            liquidity = Math.sqrt(amount0Desired * amount1Desired);
        } else {
            liquidity = Math.min(
                (amount0Desired * supply) / uint256(_reserve0), (amount1Desired * supply) / uint256(_reserve1)
            );
        }

        if (liquidity == 0) {
            revert ZeroLiquidityMinted();
        }

        if (amount0Desired < amount0Min || amount1Desired < amount1Min) {
            revert SlippageExceeded();
        }

        _mint(to, liquidity);
        _sync();

        emit LiquidityAdded(msg.sender, amount0Desired, amount1Desired, liquidity);
    }

    function removeLiquidity(uint256 liquidity, uint256 amount0Min, uint256 amount1Min, address to)
        external
        nonReentrant
        returns (uint256 amount0, uint256 amount1)
    {
        if (to == address(0)) {
            revert InvalidRecipient();
        }

        uint256 supply = totalSupply();
        if (liquidity == 0 || supply == 0) {
            revert InsufficientLiquidityBurned();
        }

        amount0 = (liquidity * IERC20(token0).balanceOf(address(this))) / supply;
        amount1 = (liquidity * IERC20(token1).balanceOf(address(this))) / supply;

        if (amount0 < amount0Min || amount1 < amount1Min) {
            revert SlippageExceeded();
        }

        _burn(msg.sender, liquidity);
        IERC20(token0).safeTransfer(to, amount0);
        IERC20(token1).safeTransfer(to, amount1);
        _sync();

        emit LiquidityRemoved(msg.sender, amount0, amount1, liquidity);
    }

    function swap(address tokenIn, uint256 amountIn, uint256 amountOutMin, address to)
        external
        nonReentrant
        returns (uint256 amountOut)
    {
        if (to == address(0)) {
            revert InvalidRecipient();
        }

        if (amountIn == 0) {
            revert InsufficientInput();
        }

        bool zeroForOne;
        if (tokenIn == token0) {
            zeroForOne = true;
        } else if (tokenIn == token1) {
            zeroForOne = false;
        } else {
            revert InvalidToken();
        }

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        uint256 reserveIn = zeroForOne ? _reserve0 : _reserve1;
        uint256 reserveOut = zeroForOne ? _reserve1 : _reserve0;
        amountOut = getAmountOut(amountIn, reserveIn, reserveOut);

        if (amountOut < amountOutMin) {
            revert SlippageExceeded();
        }

        IERC20(zeroForOne ? token1 : token0).safeTransfer(to, amountOut);
        _sync();

        emit SwapExecuted(msg.sender, tokenIn, amountIn, amountOut, to);
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256) {
        if (amountIn == 0 || reserveIn == 0 || reserveOut == 0) {
            revert InsufficientInput();
        }

        uint256 amountInWithFee = amountIn * (BPS_DENOMINATOR - FEE_BPS);
        return (reserveOut * amountInWithFee) / ((reserveIn * BPS_DENOMINATOR) + amountInWithFee);
    }

    function _sync() internal {
        _reserve0 = uint112(IERC20(token0).balanceOf(address(this)));
        _reserve1 = uint112(IERC20(token1).balanceOf(address(this)));
    }
}
