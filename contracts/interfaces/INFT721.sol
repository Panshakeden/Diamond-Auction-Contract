pragma solidity ^0.8.0;

interface INFT721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenid
    ) external;

function ownerOf(uint256 tokenId) external view returns (address owner);

}

