// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import{IERC721} from "../interfaces/IERC721.sol";
import{IERC20} from "../interfaces/IERC20.sol";

// import {SafeMath} from "../libraries/SafeMath.sol";

contract AuctionFacet {

    LibAppStorage.Layout internal l;

    event Successful();
    event bidSuccessful(address indexed sender,uint amount);
    event withdrawBid(address indexed bidder, uint amount);
    event transferBid(address highestBider,uint highestBid );


    function start(address _nft) external {
        require(l.seller == msg.sender, "you are not the owner please");
        require(!l.hasStarted, "started auctioning");

        l.hasStarted = true;
        l.endAt = uint32(block.timestamp + 60);

        IERC721(_nft).transferFrom(l.seller, address(this), l.nftId);

        emit Successful();
    }

     function bid(address token, uint256 amount) external {
        require(l.hasStarted, "Auction has not started yet");
        require(!l.hasEnded, "Auction has ended");
        require(block.timestamp < l.endAt, "Auction has ended");
        require(amount >= l.highestBid, "Bid must be greater than or equal to current highest bid");

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        if (l.highestBider != address(0)) {
            // IERC20(token).transfer(_highestBider, l.bids[_highestBider]);
            // l.bids[_highestBider] = 0;
        }

        l.highestBid = amount;
        l.highestBider = msg.sender;

        emit bidSuccessful(msg.sender, amount);
    }


    function end(address _nft)external {
        require(l.hasStarted,"not started");
        require(l.hasEnded,"ended");
        require(block.timestamp>=l.endAt);

        l.hasEnded=true;

     if (l.highestBider != address(0)) {
          IERC721(_nft).transferFrom(address(this), l.highestBider, l.nftId);
        //  IERC721(_nft).transfer(l.highestBid);
     }
     else{
         IERC721(_nft).transferFrom(address(this),l.seller , l.nftId);
     }

     emit  transferBid(l.highestBider,l.highestBid );
    }
}




interface IWOW {
    function mint(address _to, uint256 _amount) external;
    function totalSupply() external returns (uint256);
}



