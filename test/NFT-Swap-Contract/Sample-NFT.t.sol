// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Sample} from "../../src/NFT-Swap-Contract/Sample-NFT.sol";

contract SampleTest is Test {
    Sample public sample;

    function setUp() public {
        sample = new Sample();
    }

    function testNameAndSymbol() public {
        assertEq(sample.name(), "Sample-NFT");
        assertEq(sample.symbol(), "SN");
    }

    function testMint() public {
        sample.mint(121);
        assertEq(sample.ownerOf(121), address(this));
    }
}
