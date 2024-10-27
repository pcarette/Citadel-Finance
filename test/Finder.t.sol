// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {SynthereumFinder} from "../src/Finder.sol"; // Assuming Finder.sol is in src directory

contract FinderTest is Test {
    
    address sender = address(0x5);
    address maintainer = address(0x1);
    
    SynthereumFinder finder;

    // Random Ethereum addresses for testing
    bytes32 interfaceName1 = bytes32(abi.encodePacked("interface1"));
    bytes32 interfaceName2 = bytes32(abi.encodePacked("interface2"));
    address implementationAddress1;
    address implementationAddress2;
    address implementationAddress3;

    // Events (matches the Finder contract)
    event InterfaceImplementationChanged(
        bytes32 indexed interfaceName,
        address indexed newImplementationAddress
    );

    function setUp() public {
        // Initialize the roles struct
        SynthereumFinder.Roles memory roles = SynthereumFinder.Roles({
            admin: sender,
            maintainer: maintainer
        });

        // Deploy the Finder contract with the roles struct
        finder = new SynthereumFinder(roles); // Deploy the Finder contract
        implementationAddress1 = address(
            uint160(uint256(keccak256("address1")))
        );
        implementationAddress2 = address(
            uint160(uint256(keccak256("address2")))
        );
        implementationAddress3 = address(
            uint160(uint256(keccak256("address3")))
        );
    }

    function testCannotChangeImplementationAsNonMaintainer() public {
        vm.prank(sender); // Impersonate the sender address for the next operation
        vm.expectRevert(); // Expect revert since sender is not maintainer
        finder.changeImplementationAddress(
            interfaceName1,
            implementationAddress1
        );
    }

    function testCannotFindUnknownInterface() public {
        vm.expectRevert(); // Expect revert when trying to get an unknown interface
        finder.getImplementationAddress(interfaceName1);
    }

    function testSetAndFindInterface() public {
        vm.prank(maintainer); // Impersonate maintainer for the next operation
        finder.changeImplementationAddress(
            interfaceName1,
            implementationAddress1
        );

        // Assert that the interface address was set correctly
        assertEq(
            finder.getImplementationAddress(interfaceName1),
            implementationAddress1
        );
    }

    function testSupportsMultipleInterfaces() public {
        vm.startPrank(maintainer);
        finder.changeImplementationAddress(
            interfaceName1,
            implementationAddress1
        );
        finder.changeImplementationAddress(
            interfaceName2,
            implementationAddress2
        );

        // Check that both interface addresses were set correctly
        assertEq(
            finder.getImplementationAddress(interfaceName1),
            implementationAddress1
        );
        assertEq(
            finder.getImplementationAddress(interfaceName2),
            implementationAddress2
        );
        vm.stopPrank();
    }

    function testResetAndFindInterface() public {
        vm.startPrank(maintainer);
        finder.changeImplementationAddress(
            interfaceName1,
            implementationAddress1
        );

        finder.changeImplementationAddress(
            interfaceName2,
            implementationAddress2
        );
        //Reset interface1 with new address
        vm.expectEmit(true, true, true, true);
        emit InterfaceImplementationChanged(
            interfaceName1,
            implementationAddress3
        );

        finder.changeImplementationAddress(
            interfaceName1,
            implementationAddress3
        );

        vm.stopPrank();

        // Assert that the interface was reset correctly
        assertEq(
            finder.getImplementationAddress(interfaceName2),
            implementationAddress2
        );
        assertEq(
            finder.getImplementationAddress(interfaceName1),
            implementationAddress3
        );
    }
}
