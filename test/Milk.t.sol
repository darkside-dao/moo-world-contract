// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../src/Milk.sol";

contract MilkTest is Test {
    Milk milk;

    function setUp() public {
        milk = new Milk();
    }

    function testMint() public {
        milk.addMinter(address(this));
        milk.mint(address(this), 1e18);
        assertEq(milk.balanceOf(address(this)), 1e18);
    }

    function testaddMinter() public {
        milk.addMinter(address(this));
        milk.mint(address(this), 1e18);
        milk.burnFrom(address(this), 1e18);
        assertEq(milk.balanceOf(address(this)), 0);
    }

    function testFailremoveMinter() public {
        testaddMinter();
        milk.removeMinter(address(this));
        milk.mint(address(this), 1e18);
    }
}