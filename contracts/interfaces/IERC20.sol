pragma solidity ^0.8.20;

interface IERC20 {
   
   function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

}

