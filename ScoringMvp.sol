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

contract ScoringMvp is Owned {

    mapping(address => Expert) public experts;
    address[] public expertIndex; 
    
    enum ExpertType {
        NotExpert,
        HR,
        Lawyer,       
        Analyst,
        TechSpec
    }

    struct Expert {   
        uint index;
        ExpertType expertType; 
    }

    function ScoringMvp() public {}

    function isExpert(address _address) private constant returns(bool) {
        return experts[_address].expertType != ExpertType.NotExpert;
    }

    function addOrUpdateExpert(ExpertType expertType) public returns(uint) {
        require(expertType != ExpertType.NotExpert);
        Expert storage expert = experts[msg.sender];
        if (!isExpert(msg.sender)) {
            expert.index = expertIndex.push(msg.sender) - 1;
        }

        expert.expertType = expertType;     
        return expert.index;
    }
    
    function deleteExpert(address _address) public onlyOwner returns(uint) {
        require(isExpert(_address));    
        uint exdpertToDelete = experts[_address].index;
        address keyToMove = expertIndex[expertIndex.length-1];
        expertIndex[exdpertToDelete] = keyToMove;
        experts[keyToMove].index = exdpertToDelete; 
        expertIndex.length--;
        delete experts[_address];
        return exdpertToDelete;
    }
}