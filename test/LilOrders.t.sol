// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {LilOrders} from "../src/LilOrders.sol";
import {Test} from "../lib/forge-std/src/Test.sol";
import {MockERC20} from "@solady/test/utils/mocks/MockERC20.sol";

contract LilOrdersTest is Test {
    error OutOfTime();
    error Unauthorized();

    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    LilOrders internal orders;
    MockERC20 internal erc20;

    address alice;
    address bob;

    function setUp() public {
        orders = new LilOrders();
        erc20 = new MockERC20("TEST", "TEST", 18);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        payable(alice).transfer(1 ether);
        erc20.mint(bob, 100 ether);
        vm.prank(bob);
        erc20.approve(address(orders), type(uint256).max);
    }

    function testDeploy() public {
        new LilOrders();
    }

    function testETHforERC20() public {
        LilOrders.Order memory order;
        order.tokenIn = ETH;
        order.tokenOut = address(erc20);
        order.amountIn = 1 ether;
        order.amountOut = 100 ether;
        order.maker = alice;
        order.validUntil = type(uint40).max;

        vm.prank(alice);
        assertEq(alice.balance, 1 ether);
        orders.make{value: 1 ether}(order);
        assertEq(alice.balance, 0);

        vm.prank(bob);
        orders.execute(keccak256(abi.encode(order)));

        assertEq(erc20.balanceOf(alice), 100 ether);
        assertEq(bob.balance, 1 ether);
    }

    function testCancelOrderETH() public {
        LilOrders.Order memory order;
        order.tokenIn = ETH;
        order.tokenOut = address(erc20);
        order.amountIn = 1 ether;
        order.amountOut = 100 ether;
        order.maker = alice;
        order.validUntil = type(uint40).max;

        vm.prank(alice);
        assertEq(alice.balance, 1 ether);
        orders.make{value: 1 ether}(order);
        assertEq(alice.balance, 0);

        vm.prank(alice);
        orders.cancel(keccak256(abi.encode(order)));

        vm.prank(bob);
        vm.expectRevert(OutOfTime.selector); // Guarded.
        orders.execute(keccak256(abi.encode(order)));

        assertEq(alice.balance, 1 ether); // Refunded.
    }

    function testCancelOrderFailUnauthorized() public {
        LilOrders.Order memory order;
        order.tokenIn = ETH;
        order.tokenOut = address(erc20);
        order.amountIn = 1 ether;
        order.amountOut = 100 ether;
        order.maker = alice;
        order.validUntil = type(uint48).max;

        vm.prank(alice);
        assertEq(alice.balance, 1 ether);
        orders.make{value: 1 ether}(order);
        assertEq(alice.balance, 0);

        vm.prank(bob);
        vm.expectRevert(Unauthorized.selector); // Guarded.
        orders.cancel(keccak256(abi.encode(order)));
    }
}
