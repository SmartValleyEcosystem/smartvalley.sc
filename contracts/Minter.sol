pragma solidity ^ 0.4.18;

import "./Owned.sol";
import "./SmartValleyToken.sol";

contract Minter is Owned {

    uint256 public amountToGift = 1200;

    mapping(address => uint) public receiversDateMap;

    SmartValleyToken private token;

    function Minter(address tokenAddress) public payable {
        token = SmartValleyToken(tokenAddress);
    }

    function giftTokens () public returns(uint256) {
        require(receiversDateMap[msg.sender] == 0 || now - receiversDateMap[msg.sender] >= 3 days);
        token.mintTokens(msg.sender, amountToGift);
        receiversDateMap[msg.sender] = now;
        return token.balanceOf(msg.sender);
    }

    function () payable public {}
    
    function setTokenAddress (address tokenAddress) public onlyOwner {
        require(token != tokenAddress);
        token = SmartValleyToken(tokenAddress);
    }

    function setAmountToGift (uint256 _amountToGift) public onlyOwner {
        require(_amountToGift > 0);
        amountToGift = _amountToGift;
    }
}