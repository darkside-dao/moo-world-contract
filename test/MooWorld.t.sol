//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../src/Whitelist.sol";
import "../src/MooWorld.sol";

contract MooWorldTest is Test {
    Whitelist whitelist;
    MooWorld mooWorld;

    function setUp() public {
        whitelist = new Whitelist("whitelist/");
        mooWorld = new MooWorld("collection/", address(whitelist));
        whitelist.setBurner(address(mooWorld));
    }

    function testMint() public {
        uint8 quantity = 10;
        uint256 price = mooWorld.mintPrice();
        // Start & Skip presale
        mooWorld.startPresale();
        vm.warp(block.timestamp + mooWorld.saleAfter());
        // Minting
        vm.prank(msg.sender);
        mooWorld.mint{value: quantity * price}(quantity);
        assertEq(mooWorld.balanceOf(msg.sender), quantity);
    }

    function testPresaleMint() public {
        uint256 mintPrice = mooWorld.mintPrice();
        uint8 quantity = 1;
        // Minting Whitelist NFT
        whitelist.give(msg.sender, quantity);
        // Start Presale
        mooWorld.startPresale();
        // Minting Presale
        vm.prank(msg.sender);
        mooWorld.presaleMint{value: mintPrice}(quantity);
        assertEq(mooWorld.balanceOf(msg.sender), quantity);
    }

    function testGive() public {
        mooWorld.giveaway(msg.sender, 12);
        assertEq(mooWorld.balanceOf(msg.sender), 12);
    }

    function testBurn() public {
        testMint();
        uint256 tokenId = mooWorld.tokenOfOwnerByIndex(msg.sender, 0);
        // Burning
        vm.prank(msg.sender);
        mooWorld.burn(tokenId);
        assertEq(mooWorld.balanceOf(msg.sender), 9);
    }

    function testWithdraw() public {
        testMint();
        uint256 balance = address(mooWorld).balance;
        uint256 balanceBefore = msg.sender.balance;
        mooWorld.transferOwnership(msg.sender);
        vm.prank(msg.sender);
        mooWorld.withdraw();
        assertEq(msg.sender.balance - balanceBefore, balance);
    }
}