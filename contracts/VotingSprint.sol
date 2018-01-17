pragma solidity ^ 0.4.18;

import "./Owned.sol";
import "./BalanceFreezer.sol";
import "./SmartValleyToken.sol";

contract VotingSprint is Owned {
    
    uint public startDate;                                                              
    uint public endDate;                                                                
    uint public acceptanceThreshold;  
    uint public maximumScore;                                                     

    BalanceFreezer public freezer;
    SmartValleyToken public token;
                                  
    mapping(uint => bool) public projects;                                     
    mapping(uint => uint) public projectVotes;                                 
    mapping(address => uint) public investorTokenAmounts;
    mapping(uint => mapping( address => uint)) public investorVotes;

    function VotingSprint(uint _durationDays, uint256[] _projectsIds, address _token, address _freezer) public {
        freezer = BalanceFreezer(_freezer);
        token = SmartValleyToken(_token);

        startDate = now;
        endDate = startDate + _durationDays * 1 days;

        for (uint i = 0; i < _projectsIds.length; i++) {
            projects[_projectsIds[i]] = true;
        }
    }

    function submitVote(uint _externalId, uint _valueWithDecimals) external {
        require(_valueWithDecimals > 0 && projects[_externalId] && investorVotes[_externalId][msg.sender] == 0 && token.getAvailableBalance(msg.sender) >= _valueWithDecimals);
        
        if (investorTokenAmounts[msg.sender] == 0) {
            investorTokenAmounts[msg.sender] = _valueWithDecimals;
            freezer.freeze(_valueWithDecimals, (endDate - startDate) / 1 days);
            maximumScore += _valueWithDecimals;
        }

        investorVotes[_externalId][msg.sender] = _valueWithDecimals;
        projectVotes[_externalId] += _valueWithDecimals;
    }

    function isAccepted(uint _externalId) external constant returns(bool) {
        require(projects[_externalId]);
        return percent(projectVotes[_externalId], maximumScore, 2) >= acceptanceThreshold;
    }

    function percent(uint numerator, uint denominator, uint precision) private constant returns(uint quotient) {
        uint _numerator = numerator * 10 ** (precision+1);
        uint _quotient = ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
    }

    function setAcceptanceThreshold (uint _value) external onlyOwner {
        require(_value > 0);
        acceptanceThreshold = _value;
    }
}