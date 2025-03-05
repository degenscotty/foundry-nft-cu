// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployBasicNft} from "script/DeployBasicNft.s.sol";
import {BasicNft} from "src/BasicNft.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract NonReceiver {}

contract Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract BasicNftTest is Test {
    DeployBasicNft public deployer;
    BasicNft public basicNft;

    function setUp() public {
        deployer = new DeployBasicNft();
        basicNft = deployer.run();
    }

    function testNameIsCorrect() public view {
        string memory expectedName = "Dogie";
        string memory actualName = basicNft.name();
        assert(
            keccak256(abi.encodePacked(expectedName)) == keccak256(abi.encodePacked(actualName))
        );
    }

    function testSymbolIsCorrect() public view {
        string memory expectedSymbol = "DOG";
        string memory actualSymbol = basicNft.symbol();
        assert(
            keccak256(abi.encodePacked(expectedSymbol)) == keccak256(abi.encodePacked(actualSymbol))
        );
    }

    function testInitialTokenDoesNotExist() public {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, 0));
        basicNft.ownerOf(0);
    }

    function testTokenURIForNonExistentToken() public view {
        string memory uri = basicNft.tokenURI(0);
        assertEq(uri, "");
    }

    function testMintNft() public {
        address user = makeAddr("user");
        string memory tokenUri = "ipfs://exampleUri1";
        vm.prank(user);
        basicNft.mintNft(tokenUri);
        assertEq(basicNft.ownerOf(0), user);
        assertEq(basicNft.tokenURI(0), tokenUri);
        assertEq(basicNft.balanceOf(user), 1);
    }

    function testMintMultipleNfts() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        string memory tokenUri1 = "ipfs://exampleUri1";
        string memory tokenUri2 = "ipfs://exampleUri2";
        vm.prank(user1);
        basicNft.mintNft(tokenUri1);
        vm.prank(user2);
        basicNft.mintNft(tokenUri2);
        assertEq(basicNft.ownerOf(0), user1);
        assertEq(basicNft.ownerOf(1), user2);
        assertEq(basicNft.tokenURI(0), tokenUri1);
        assertEq(basicNft.tokenURI(1), tokenUri2);
        assertEq(basicNft.balanceOf(user1), 1);
        assertEq(basicNft.balanceOf(user2), 1);
    }

    function testMintWithEmptyUri() public {
        address user = makeAddr("user");
        vm.prank(user);
        basicNft.mintNft("");
        assertEq(basicNft.ownerOf(0), user);
        assertEq(basicNft.tokenURI(0), "");
        assertEq(basicNft.balanceOf(user), 1);
    }

    function testMintToNonReceiverReverts() public {
        NonReceiver nonReceiver = new NonReceiver();
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC721Errors.ERC721InvalidReceiver.selector,
                address(nonReceiver)
            )
        );
        vm.prank(address(nonReceiver));
        basicNft.mintNft("ipfs://exampleUri");
    }

    function testMintToReceiverSucceeds() public {
        Receiver receiver = new Receiver();
        vm.prank(address(receiver));
        basicNft.mintNft("ipfs://exampleUri");
        assertEq(basicNft.ownerOf(0), address(receiver));
        assertEq(basicNft.tokenURI(0), "ipfs://exampleUri");
    }

    function testTokenCounterIncrementsCorrectly() public {
        address user = makeAddr("user");
        vm.prank(user);
        basicNft.mintNft("uri1");
        vm.prank(user);
        basicNft.mintNft("uri2");
        vm.prank(user);
        basicNft.mintNft("uri3");
        assertEq(basicNft.ownerOf(0), user);
        assertEq(basicNft.ownerOf(1), user);
        assertEq(basicNft.ownerOf(2), user);
        assertEq(basicNft.tokenURI(0), "uri1");
        assertEq(basicNft.tokenURI(1), "uri2");
        assertEq(basicNft.tokenURI(2), "uri3");
        assertEq(basicNft.balanceOf(user), 3);
    }
}
