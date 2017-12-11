pragma solidity ^ 0.4.18;

import "./Owned.sol";
import "./SmartValleyToken.sol";

contract Minter is Owned {

    uint256 public amountToGift = 1200;

    mapping(address => uint) public receiversDateMap;

    SmartValleyToken private token;

    function Minter(address _tokenAddress) public payable {
        token = SmartValleyToken(_tokenAddress);
    }

    function giftTokens () public {
        require(addressCanGiftTokens());
        var dec = token.decimals;
        token.mintTokens(msg.sender, amountToGift * 10 ** dec);
        receiversDateMap[msg.sender] = now;
    }

    function addressCanGiftTokens() view public returns(bool) {
        return receiversDateMap[msg.sender] == 0 || now - receiversDateMap[msg.sender] >= 3 days;
    }

    function () payable public {}
    
    function setTokenAddress (address _tokenAddress) public onlyOwner {
        require(token != _tokenAddress && _tokenAddress != 0);
        token = SmartValleyToken(_tokenAddress);
    }

    function setAmountToGift (uint256 _amountToGift) public onlyOwner {
        require(_amountToGift > 0);
        amountToGift = _amountToGift;
    }
}