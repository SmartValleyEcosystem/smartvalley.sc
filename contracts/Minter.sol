pragma solidity ^ 0.4.18;

import "./Owned.sol";

contract Minter is Owned {

    uint256 public amountToGift = 1200;

    address[] public receivers;
    mapping(address => uint) public receiversBalanceMap;
    mapping(address => uint) public receiversDateMap;

    function Minter() public payable {}

    function giftTokens (address _receiver) public onlyOwner returns(uint256) {
        require(receiversDateMap[_receiver] == 0 || now - receiversDateMap[_receiver] >= 3 days);
        if (receiversDateMap[_receiver] == 0) {
        receivers.push(_receiver);
        }
        receiversBalanceMap[_receiver] += amountToGift;
        receiversDateMap[_receiver] = now;
        return receiversBalanceMap[_receiver];
    }

    function () payable public {}

    function setAmountToGift (uint256 _amountToGift) public onlyOwner {
        require(_amountToGift > 0);
        amountToGift = _amountToGift;
    }
}