pragma solidity ^ 0.4.18;

import "./Owned.sol";
import "./SmartValleyToken.sol";

contract Minter is Owned {

    uint256 public amountToGift = 1200;

    mapping(address => uint) public receiversDateMap;

    SmartValleyToken private token;

    function Minter(address _tokenAddress) public {
        token = SmartValleyToken(_tokenAddress);
    }

    function getTokens () public {
        require(addresscanGetTokens(msg.sender));
        token.mintTokens(msg.sender, amountToGift * (10 ** uint(token.decimals())));
        receiversDateMap[msg.sender] = now;
    }

    function addresscanGetTokens(address _receiverAddress) view public returns(bool) {
        return receiversDateMap[_receiverAddress] == 0 || now - receiversDateMap[_receiverAddress] >= 3 days;
    }

    function setTokenAddress (address _tokenAddress) public onlyOwner {
        require(token != _tokenAddress && _tokenAddress != 0);
        token = SmartValleyToken(_tokenAddress);
    }

    function setAmountToGift (uint256 _amountToGift) public onlyOwner {
        require(_amountToGift > 0);
        amountToGift = _amountToGift;
    }
}