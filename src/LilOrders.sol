// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.25;

/// @dev Lil-est order protocol for ETH/ERC20/ERC721.
/// @author z0r0z.eth
/// @custom:coauthor @willmorriss4 (fixed make() vuln)
/// @custom:coauthor josephdara.eth (fixed cancel() vuln)
contract LilOrders {
    error OutOfTime();
    error Unauthorized();
    error InvalidValue();

    event Made(bytes32 indexed orderHash);

    mapping(bytes32 orderHash => Order) orders;

    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct Order {
        uint96 nonce;
        address tokenIn;
        address tokenOut;
        uint256 amountIn; // Works as NFT ID.
        uint256 amountOut; // Works as NFT ID.
        address maker;
        uint48 validAfter;
        uint48 validUntil;
    }

    function make(Order calldata order) public payable {
        if (msg.sender != order.maker) revert Unauthorized();
        if (order.tokenIn == ETH) {
            if (msg.value != order.amountIn) revert InvalidValue();
        }
        bytes32 orderHash = keccak256(abi.encode(order));
        orders[orderHash] = order;
        emit Made(orderHash);
    }

    function cancel(bytes32 order) public {
        Order memory _order = orders[order];
        delete orders[order];
        if (msg.sender != _order.maker) revert Unauthorized();
        safeTransferETH(msg.sender, _order.amountIn);
    }

    function execute(bytes32 order) public payable {
        Order memory _order = orders[order];
        delete orders[order];
        if (block.timestamp < _order.validAfter || block.timestamp > _order.validUntil) {
            revert OutOfTime();
        }
        if (_order.tokenIn == ETH) safeTransferETH(msg.sender, _order.amountIn);
        else safeTransferFrom(_order.tokenIn, _order.maker, msg.sender, _order.amountIn);
        if (_order.tokenOut == ETH) safeTransferETH(_order.maker, _order.amountOut);
        else safeTransferFrom(_order.tokenOut, msg.sender, _order.maker, _order.amountOut);
    }
}

/// @dev Sourced from the pristine machinations of the Solady solidity library.
function safeTransferETH(address to, uint256 amount) {
    assembly ("memory-safe") {
        if iszero(call(gas(), to, amount, codesize(), 0x00, codesize(), 0x00)) {
            mstore(0x00, 0xb12d13eb)
            revert(0x1c, 0x04)
        }
    }
}

/// @dev Sourced from the pristine machinations of the Solady solidity library.
function safeTransferFrom(address token, address from, address to, uint256 amount) {
    assembly ("memory-safe") {
        let m := mload(0x40)
        mstore(0x60, amount)
        mstore(0x40, to)
        mstore(0x2c, shl(96, from))
        mstore(0x0c, 0x23b872dd000000000000000000000000)
        if iszero(
            and(
                or(eq(mload(0x00), 1), iszero(returndatasize())),
                call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
            )
        ) {
            mstore(0x00, 0x7939f424)
            revert(0x1c, 0x04)
        }
        mstore(0x60, 0)
        mstore(0x40, m)
    }
}
