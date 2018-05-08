pragma solidity ^ 0.4.22;

import "./Owned.sol";

contract EtherManager is Owned {

    uint256 public weiAmountToGift = 1 ether;
    mapping(address => bool) public receiversMap;
    address[] public receivers;

    constructor() public payable {}

    function giftEth (address _receiver) public onlyOwner returns(uint256) {
        require(address(this).balance >= weiAmountToGift && receiversMap[_receiver] == false);
        _receiver.transfer(weiAmountToGift);
        receiversMap[_receiver] = true;
        receivers.push(_receiver);
        return address(this).balance;
    }

    function () payable public {}

    function setAmountToGift (uint256 _weiAmountToGift) public onlyOwner {
        require(_weiAmountToGift > 0);
        weiAmountToGift = _weiAmountToGift;
    }

    function withdrawEth() external onlyOwner {
        owner.transfer(address(this).balance);
    }
}