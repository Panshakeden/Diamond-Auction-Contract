// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import{INFT721} from "../interfaces/INFT721.sol";
import{IERC20} from "../interfaces/IERC20.sol";

// import {SafeMath} from "../libraries/SafeMath.sol";

contract AuctionFacet {

    LibAppStorage.Layout internal l;

    event Successful();
    event bidSuccessful(address indexed sender,uint amount);
    event withdrawBid(address indexed bidder, uint amount);
    event transferBid(address highestBider,uint highestBid );


    function startAuction(address _nft, uint256 _tokenId) external {
        require(l.seller == msg.sender, "you are not the owner");
        require(!l.hasStarted, "started auctioning");

        l.hasStarted = true;
        l.endAt = uint256(block.timestamp + 60);

        l.nft = _nft;
        l.nftId= _tokenId;
        l.highestBider = address(0);
        l.highestBid = 0;

        INFT721(l.nft).transferFrom(l.seller, address(this), l.nftId);

        emit Successful();
    }

     function bidNFT( uint256 _amount) external {
        require(l.hasStarted, "Auction has not started yet");
        require(!l.hasEnded, "Auction has ended");
        require(block.timestamp < l.endAt, "Auction ended");
        require(_amount >= l.highestBid, "Bid must be greater than or equal to current highest bid");


        if (l.highestBider != address(0)) {
            // Calculate incentives and distribute fees
            uint256 totalFee = _amount - l.highestBid;
            uint256 burnFee = (totalFee * 2) / 100;
            uint256 daoFee = (totalFee * 2) / 100;
            uint256 outbidRefund = (totalFee * 3) / 100;
            uint256 teamFee = (totalFee * 2) / 100;
            uint256 lastinteractFee = totalFee / 100;

            // Transfer fees to respective addresses
            LibAppStorage._transferFrom(address(this), address(0), burnFee);
            LibAppStorage._transferFrom(address(this), address(0), daoFee);
            LibAppStorage._transferFrom(address(this),address(0), outbidRefund );
             LibAppStorage._transferFrom(address(this),address(0), teamFee);
            LibAppStorage._transferFrom(address(this),l.lastInteract, lastinteractFee);
        }

        LibAppStorage._transferFrom(msg.sender, address(this), _amount);


        l.highestBid = _amount;
        l.highestBider = msg.sender;

        emit bidSuccessful(msg.sender, _amount);
    }


    function endAuction(address _nft)external {
        require(l.hasStarted,"not started");
        require(l.hasEnded,"ended");
        require(block.timestamp>=l.endAt);

        l.hasEnded=true;

     if (msg.sender != address(0)) {
          INFT721(_nft).transferFrom(address(this), msg.sender, l.nftId);
     }
     else{
         INFT721(_nft).transferFrom(address(this),l.seller , l.nftId);
     }

     emit  transferBid(l.highestBider,l.highestBid );
    }
}




