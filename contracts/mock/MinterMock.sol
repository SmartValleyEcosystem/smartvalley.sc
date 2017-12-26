pragma solidity ^ 0.4.18;

import "../Minter.sol";

contract MinterMock is Minter {
    function MinterMock(address _tokenAddress) Minter(_tokenAddress) public {
    }
}