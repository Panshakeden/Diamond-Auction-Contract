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

   

 // Function to calculate the percentage cut based on the provided amount
    function calculatePercentageCut(uint amount) internal pure returns (uint) {
        return (amount * 10) / 100; // 10% cut
    }

    // Function for placing a bid in an auction and distributing tax
    function bidWithToken(
        uint auctionId,
        uint price,
        address _outbidBidder,
        address _lastInteractor
    ) external {
        require(l.balances[msg.sender] > price, "INSUFFICIENT_BALANCE");

        uint percentageCut;

        if (l.bids[auctionId].length == 0) {
            require(price >= l.auctions[auctionId].starterPrice, "STARTING_PRICE_MUST_BE_GREATER");

            percentageCut = calculatePercentageCut(price);
            distributeFee(
                percentageCut,
                _outbidBidder,
                _lastInteractor
            );

            LibAppStorage.Bid memory _newBid = LibAppStorage.Bid({
                author: msg.sender,
                amount: price - percentageCut,
                auctionId: auctionId
            });
            l.bids[auctionId].push(_newBid);
        } else {
            require(price > l.bids[auctionId][l.bids[auctionId].length - 1].amount, "PRICE_MUST_BE_GREATER_THAN_LAST_BIDDED");

            percentageCut = calculatePercentageCut(price - l.bids[auctionId][l.bids[auctionId].length - 1].amount);
            distributeFee(
                percentageCut,
                l.bids[auctionId][l.bids[auctionId].length - 1].author,
                _lastInteractor
            );

            LibAppStorage.Bid memory _newBid = LibAppStorage.Bid({
                author: msg.sender,
                amount: price - percentageCut,
                auctionId: auctionId
            });
            l.bids[auctionId].push(_newBid);
        }
    }

    // Function to distribute the tax according to the breakdown
    function distributeFee(
        uint _fee,
        address _outbidBidder,
        address _lastInteractor
    ) internal {
        // Calculate each portion of the tax
        uint toBurn = (_fee * 20) / 100; // 2% burned
        uint toDAO = (_fee * 20) / 100; // 2% to DAO Wallet
        uint toOutbidBidder = (_fee * 30) / 100; // 3% back to the outbid bidder
        uint toTeam = (_fee * 20) / 100; // 2% to Team Wallet
        uint toInteractor = (_fee * 10) / 100; // 1% to Interactor Wallet

        // Transfer the respective amounts to the specified wallets
        LibAppStorage._transferFrom(address(this), address(0x84c888Eed28F6587B6005CA00e3a2FA9bb40D11a), toDAO);
        LibAppStorage._transferFrom(address(this), _outbidBidder, toOutbidBidder);
        LibAppStorage._transferFrom(address(this), address(0), toTeam);
        LibAppStorage._transferFrom(address(this), address(0), toBurn);
        LibAppStorage._transferFrom(address(this), _lastInteractor, toInteractor);
    }




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
    


    function auctionClosed(uint256 auctionId)external {
        LibAppStorage.Auction storage auction = l.auctions[auctionId];
        require(block.timestamp >= l.auctions[auctionId].endAt, "Auction ended");
        
        require(
        msg.sender == auction.author || 
        msg.sender == l.bids[auctionId][l.bids[auctionId].length - 1].author,
        "You can't claim");

          
    uint256 BidderIndex= l.bids[auctionId].length - 1;
    uint256 BidderPrice = l.bids[auctionId][BidderIndex].amount;
    LibAppStorage._transferFrom(address(this), auction.author, BidderPrice);

    address winningBidder = l.bids[auctionId][BidderIndex].author;

    INFT721(auction.tokenContract).transferFrom(address(this), winningBidder, auction.tokenId);

    // Emit an event indicating successful auction closure
    emit AuctionClosed(auctionId, auction.author, winningBidder, BidderPrice);
}
    
}




