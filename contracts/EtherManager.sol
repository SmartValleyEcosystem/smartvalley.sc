pragma solidity ^ 0.4.24;

import "./Owned.sol";

contract EtherManager is Owned {

    uint256 public amountToGiftWei = 1 ether;
    mapping(address => bool) public receiversMap;
    address[] public receivers;

    constructor() public payable {}

    function giftEth(address _receiver) external onlyOwner {
        require(address(this).balance >= amountToGiftWei, "not enough funds for the transfer");
        require(receiversMap[_receiver] == false, "specified account already received free ETH");

        _receiver.transfer(amountToGiftWei);
        receiversMap[_receiver] = true;
        receivers.push(_receiver);
    }

    function () payable public {}

    function setAmountToGift(uint256 _amountToGiftWei) external onlyOwner {
        require(_amountToGiftWei > 0, "amount to gift cannot be zero");
        amountToGiftWei = _amountToGiftWei;
    }

    function withdraw() external onlyOwner {
        owner.transfer(address(this).balance);
    }
}