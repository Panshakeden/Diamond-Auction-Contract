// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import{INFT721} from "../interfaces/INFT721.sol";
import{IERC20} from "../interfaces/IERC20.sol";


contract AuctionFacet {

    LibAppStorage.Layout public l;

    event CreateActionSuccessful(address indexed tokenContractAddress, uint256 indexed tokenId);
    event bidSuccessful(address indexed sender,uint amount);
    event AuctionClosed(uint256 indexed auctionId, address author, address indexed winningBidder, uint256 BidAmount);

    event transferBid(address highestBider,uint highestBid );


//    function getStarted() view external returns(bool) {
//         return l.hasStarted;
//     }

    function createAuction(address _tokenContractAddress, uint256 _tokenId,uint256 _starterPrice,uint256 _endAt) external {
        require(_tokenContractAddress!=address(0),"ADDRESS");
        require(INFT721(_tokenContractAddress).ownerOf(_tokenId)== msg.sender,"NOT_TOKEN_OWNER");
        INFT721(_tokenContractAddress).transferFrom(msg.sender, address(this), _tokenId);

        LibAppStorage.Auction memory _newAuction = LibAppStorage.Auction({id:l.auctions.length,tokenContract:_tokenContractAddress,tokenId:_tokenId,author:msg.sender,starterPrice:_starterPrice,endAt:_endAt});
        l.auctions.push(_newAuction);
       
        emit CreateActionSuccessful(_tokenContractAddress, _tokenId);
    }

   

    //  function bidforNFt( uint256 auctionId, uint256 _amount) external {
    //     require(msg.sender != address(0), "sorry can't access");
    //     require(block.timestamp < l.auctions[auctionId].endAt, "Auction ended");
    //     require(l.balances[msg.sender] > _amount, "sorry no much amount");
    //     require(_amount >= l.auctions[auctionId].starterPrice,"you must outbid the highest");

    //     if (l.highestBider != address(0)) {
    //         // Calculate incentives and distribute fees
    //         uint256 totalFee = _amount - l.highestBid;
    //         uint256 burnFee = (totalFee * 2) / 100;
    //         uint256 daoFee = (totalFee * 2) / 100;
    //         uint256 outbidRefund = (totalFee * 3) / 100;
    //         uint256 teamFee = (totalFee * 2) / 100;
    //         uint256 lastinteractFee = totalFee / 100;

    //         // Transfer fees to respective addresses
    //         LibAppStorage._transferFrom(address(this), address(0), burnFee);
    //         LibAppStorage._transferFrom(address(this), address(0), daoFee);
    //         LibAppStorage._transferFrom(address(this),address(0), outbidRefund );
    //          LibAppStorage._transferFrom(address(this),address(0), teamFee);
    //         LibAppStorage._transferFrom(address(this),l.lastInteract, lastinteractFee);
        // }

    //     LibAppStorage._transferFrom(msg.sender, address(this), _amount);


    //     l.highestBid = _amount;
    //     l.highestBider = msg.sender;

    //     emit bidSuccessful(msg.sender, _amount);
    // }


    function auctionClosed(uint256 auctionId)external {
        LibAppStorage.Auction storage auction = l.auctions[auctionId];
        require(block.timestamp >= l.auctions[auctionId].endAt, "Auction ended");
        
        require(
        msg.sender == auction.author || 
        msg.sender == l.bids[auctionId][l.bids[auctionId].length - 1].author,
        "YOU_DONT_HAVE_RIGHT");

          
    uint256 BidderIndex= l.bids[auctionId].length - 1;
    uint256 BidderPrice = l.bids[auctionId][BidderIndex].price;
    LibAppStorage._transferFrom(address(this), auction.author, BidderPrice);

    address winningBidder = l.bids[auctionId][BidderIndex].author;

    INFT721(auction.tokenContract).transferFrom(address(this), winningBidder, auction.tokenId);

    // Emit an event indicating successful auction closure
    emit AuctionClosed(auctionId, auction.author, winningBidder, BidderPrice);
}
    
}




