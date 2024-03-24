// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import{INFT721} from "../interfaces/INFT721.sol";
import{IERC20} from "../interfaces/IERC20.sol";


contract AuctionFacet {

    LibAppStorage.Layout public l;

    event CreateActionSuccessful(address _tokenContractAddress, uint256 _tokenId);
    event bidSuccessful(address indexed sender,uint amount);
    event withdrawBid(address indexed bidder, uint amount);
    event transferBid(address highestBider,uint highestBid );


//    function getStarted() view external returns(bool) {
//         return l.hasStarted;
//     }

    function createAuction(address _tokenContractAddress, uint256 _tokenId,uint _starterPrice,uint _endAt) external {
        require(_tokenContractAddress!=address(0),"ADDRESS");
        require(INFT721(_tokenContractAddress).ownerOf(_tokenId)== msg.sender,"NOT_TOKEN_OWNER");
        INFT721(_tokenContractAddress).transferFrom(msg.sender, address(this), _tokenId);

        LibAppStorage.Auction memory _newAuction = LibAppStorage.Auction({id:l.auctions.length,tokenContract:_tokenContractAddress,tokenId:_tokenId,author:msg.sender,starterPrice:_starterPrice,endAt:_endAt});
        l.auctions.push(_newAuction);
       
        emit CreateActionSuccessful(_tokenContractAddress, _tokenId);
    }

   
}




