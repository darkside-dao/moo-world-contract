//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../src/Whitelist.sol";

contract WhitelistTest is Test {
    Whitelist whitelist;
    string metadataURI;

    function setUp() public {
        whitelist = new Whitelist("");
    }

    function testGive() public {
        whitelist.give(msg.sender, 1);
        assertEq(whitelist.balanceOf(msg.sender), 1);
    }

    function testGive100() public {
        address[] memory addresses = new address[](100);
        for (uint256 i = 0; i < 100; i++) addresses[i] = msg.sender;
        whitelist.giveMany(addresses, 1);
        assertEq(whitelist.totalSupply(), 100);
    }

    function testBurn() public {
        testGive();
        uint256[] memory tokenIds = whitelist.tokensOfOwner(msg.sender);
        // Burning
        vm.prank(msg.sender);
        whitelist.burn(tokenIds[0]);
        assertEq(whitelist.balanceOf(msg.sender), 0);
    }

    function testTokenURI() public {
        testGive();
        assertEq(whitelist.tokenURI(0), metadataURI);
    }
}