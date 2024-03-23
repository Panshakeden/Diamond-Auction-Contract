pragma solidity ^0.8.20;

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenid
    ) external;

function ownerOf(uint256 tokenId) external view returns (address owner);

}

