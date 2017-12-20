pragma solidity ^ 0.4.18;

import "./Owned.sol";
import "./SmartValleyToken.sol";

contract Minter is Owned {

    uint256 public amountToGift = 1200;

    uint public constant REQUIRED_DAYS_FOR_RECEIVE = 3;

    mapping(address => uint) public receiversDateMap;

    SmartValleyToken public token;

    function Minter(address _tokenAddress) public {
        token = SmartValleyToken(_tokenAddress);
    }

    function getTokens () public {
        require(canGetTokens(msg.sender));
        token.mintTokens(msg.sender, amountToGift * (10 ** uint(token.decimals())));
        receiversDateMap[msg.sender] = now;
    }

    function canGetTokens(address _receiverAddress) view public returns(bool) {
        require(_receiverAddress != address(0));
        return receiversDateMap[_receiverAddress] == 0 || now - receiversDateMap[_receiverAddress] >= REQUIRED_DAYS_FOR_RECEIVE * 1 days;
    }

    function setTokenAddress (address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(0) && token != _tokenAddress && _tokenAddress != 0);
        token = SmartValleyToken(_tokenAddress);
    }

    function setAmountToGift (uint256 _amountToGift) public onlyOwner {
        require(_amountToGift > 0);
        amountToGift = _amountToGift;
    }
}