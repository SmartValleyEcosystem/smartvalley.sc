pragma solidity ^ 0.4.13;

contract Owned {

    address public owner;
    address public newOwner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
   
    function changeOwner(address _owner) onlyOwner external {
        require(_owner != 0);
        newOwner = _owner;
    }

    function confirmOwner() external {
        require(newOwner == msg.sender);
        owner = newOwner;
        delete newOwner;
    }
}

contract EtherManager is Owned {

    uint256 public weiAmountToGift = 1 ether;

    mapping(address => bool) public receiversMap;
    address[] public receivers;

    function EtherManager() public payable {}

    function giftEth (address _receiver) public onlyOwner returns(uint256) {
        require(this.balance >= weiAmountToGift && receiversMap[_receiver] == false);
        _receiver.transfer(weiAmountToGift);
        receiversMap[_receiver] = true;
        receivers.push(_receiver);
        return this.balance;
    }

    function () payable public {}

    function setAmountToGift (uint256 _weiAmountToGift) public onlyOwner {
        require(_weiAmountToGift > 0);
        weiAmountToGift = _weiAmountToGift;
    }
}