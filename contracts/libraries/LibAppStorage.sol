pragma solidity ^0.8.0;

library LibAppStorage {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    // struct UserStake {
    //     uint256 stakedTime;
    //     uint256 amount;
    //     uint256 allocatedPoints;
    // }
    struct Layout {
        //ERC20
        string name;
        string symbol;
        uint256 totalSupply;
        uint8 decimals;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        //AUCTION

        address lastInteract;
        Auction[] auctions;
        mapping(uint => Bid) bids;
    }

    struct Auction {
        uint id;
        address tokenContract;
        uint256 tokenId;
        // bool  hasStarted;
        address author;
        // bool  hasEnded;
        // uint256  highestBid;
        // address  highestBider;
        uint256 starterPrice;
        uint256 endAt;
    }

    struct Bid {
        address author;
        uint price;
        uint auctionId;
    }

    function layoutStorage() internal pure returns (Layout storage l) {
        assembly {
            l.slot := 0
        }
    }

    function _transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        Layout storage l = layoutStorage();
        uint256 frombalances = l.balances[msg.sender];
        require(
            frombalances >= _amount,
            "ERC20: Not enough tokens to transfer"
        );
        l.balances[_from] = frombalances - _amount;
        l.balances[_to] += _amount;
        emit Transfer(_from, _to, _amount);
    }
}
