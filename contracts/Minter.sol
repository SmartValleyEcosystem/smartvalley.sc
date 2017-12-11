pragma solidity ^ 0.4.18;

import "./Owned.sol";

contract Minter is Owned {

    uint256 public amountToGift = 1200;

    address[] public receivers;
    mapping(address => uint) public receiversBalanceMap;
    mapping(address => uint) public receiversDateMap;

    function Minter() public payable {}

    function giftTokens () public returns(uint256) {
        require(receiversDateMap[msg.sender] == 0 || now - receiversDateMap[msg.sender] >= 3 days);
        if (receiversDateMap[msg.sender] == 0) {
        receivers.push(msg.sender);
        }
        receiversBalanceMap[msg.sender] += amountToGift;
        receiversDateMap[msg.sender] = now;
        return receiversBalanceMap[msg.sender];
    }

    function () payable public {}

    function setAmountToGift (uint256 _amountToGift) public onlyOwner {
        require(_amountToGift > 0);
        amountToGift = _amountToGift;
    }
}