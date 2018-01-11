pragma solidity ^ 0.4.18;

import "../Minter.sol";

contract MinterMock is Minter {
    function MinterMock(address _tokenAddress) Minter(_tokenAddress) public {
    }

    function putToDateMap(address _receiverAddress, uint _days) public {
        receiversDateMap[_receiverAddress] = now + _days * 1 days;
    }
}