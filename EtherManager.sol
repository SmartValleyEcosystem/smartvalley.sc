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

    uint256 public weiAmount = 1 ether;

    mapping(address => bool) public receivers;
    address[] public addresses;

    function EtherManager() public payable {}

    function sendEth (address _receiver) public onlyOwner returns(uint256) {
        require(this.balance >= weiAmount && receivers[_receiver] != false);
        _receiver.transfer(weiAmount);
        receivers[_receiver] = true;
        addresses.push(_receiver);
        return this.balance;
    }

    function () payable public {}

    function setWithdrawalAmount (uint256 _weiAmount) public onlyOwner {
        require(_weiAmount > 0);
        weiAmount = _weiAmount;
    }
}