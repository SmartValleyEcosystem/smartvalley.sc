pragma solidity ^ 0.4.13;

contract Owned {

    address public owner;
    address public newOwner;

    function Owned() public payable {
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

contract ScorringMvp is Owned {

    mapping(address => Expert) public experts;
    address[] public expertIndex; 

    struct Expert {   
        uint index; 
    }

    function ScorringMvp() public {}

    function isExpert(address _address) private constant returns(bool isIndeed) {
        if (expertIndex.length == 0) {
             return false;
        }
        return (expertIndex[experts[_address].index] == _address);
    }

    function insertExpert() public returns(uint index) {
        require(!isExpert(msg.sender));    
        experts[msg.sender].index = expertIndex.push(msg.sender) - 1;       
        return expertIndex.length - 1;
    }
    
    function deleteExpert(address _address) public onlyOwner returns(uint index) {
        expertIndex[experts[_address].index] = expertIndex[expertIndex.length-1];
        experts[expertIndex[expertIndex.length-1]].index = experts[_address].index; 
        expertIndex.length--;    
        return experts[_address].index;
    }
}