// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";

import "../contracts/facets/AuctionTokenFacet.sol";
import "../contracts/facets/AuctionFacet.sol";
import  "../contracts/facets/NFT.sol";
import  "../contracts/interfaces/INFT721.sol";


import "forge-std/Test.sol";
import "../contracts/Diamond.sol";

import "../contracts/libraries/LibAppStorage.sol";

contract DiamondDeployer is Test, IDiamondCut {
    //contract types of facets to be deployed
    
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    AuctionTokenFacet erc20Facet;
    AuctionFacet aFacet;
    NFT erc721Token;


     address A =  address(0xa);
     address B= address(0xb);
     address C= address(0xc);
     address D= address(0xd);

    AuctionFacet boundAuction;
    AuctionTokenFacet boundToken;


    function setUp() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        erc20Facet = new AuctionTokenFacet();
        aFacet = new AuctionFacet();
        erc721Token=new  NFT();

        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](4);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );
        cut[2] = (
            FacetCut({
                facetAddress: address(aFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("AuctionFacet")
            })
        );

        cut[3] = (
            FacetCut({
                facetAddress: address(erc20Facet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("AuctionTokenFacet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        A = mkaddr("bidder a");
        B = mkaddr("bidder b");
        C = mkaddr("bidder c");
        D = mkaddr("bidder d");

        //mint test tokens
        AuctionTokenFacet(address(diamond)).mintTo(A);
        AuctionTokenFacet(address(diamond)).mintTo(B);
        AuctionTokenFacet(address(diamond)).mintTo(C);


        boundAuction = AuctionFacet(address(diamond));
        boundToken = AuctionTokenFacet(address(diamond));
    }

    function testMintedUsers()external {
        uint256 balance = boundToken.balanceOf(A);
        assertEq(balance, 100_000_000e18);
    }

      function testFailMintedUsers()external {
        uint256 balance = boundToken.balanceOf(D);
        assertEq(balance, 100_000_000e18);
    }



    function generateSelectors(
        string memory _facetName
    ) internal returns (bytes4[] memory selectors) {
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[1] = "scripts/genSelectors.js";
        cmd[2] = _facetName;
        bytes memory res = vm.ffi(cmd);
        selectors = abi.decode(res, (bytes4[]));
    }



    function mkaddr(string memory name) public returns (address) {
        address addr = address(
            uint160(uint256(keccak256(abi.encodePacked(name))))
        );
        vm.label(addr, name);
        return addr;
    }

    function switchSigner(address _newSigner) public {
        address foundrySigner = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
        if (msg.sender == foundrySigner) {
            vm.startPrank(_newSigner);
        } else {
            vm.stopPrank();
            vm.startPrank(_newSigner);
        }

    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
