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

contract EthereumManager is Owned {

    uint256 constant WEI = 1000000000000000000;
    uint256 public amount = 1;

    mapping(address => bool) public addressesWithEth;

    function EtherManager() public payable {}

    function sendEth (address _receiver) public onlyOwner returns(uint256) {
        var weiAmount = amount * WEI;
        require(this.balance >= weiAmount);
        _receiver.transfer(weiAmount);
        addressesWithEth[_receiver] = true;
        return this.balance;
    }

    function () payable public {}

    function setWithdrawalAmount (uint256 _amount) public onlyOwner {
        require(_amount > 0 && amount != _amount);
        amount = _amount;
    }
}