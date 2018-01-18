pragma solidity ^ 0.4.18;

import "./Owned.sol";
import "./BalanceFreezer.sol";
import "./SmartValleyToken.sol";

contract VotingSprint is Owned {

    uint public startDate;
    uint public endDate;
    uint public acceptanceThreshold;
    uint public maximumScore;
    uint[] public projectIds;

    BalanceFreezer public freezer;
    SmartValleyToken public token;

    mapping(uint => bool) public projects;
    mapping(uint => uint) public projectVotes;
    mapping(address => uint[]) public projectInvestorVotes;
    mapping(address => uint) public investorTokenAmounts;
    mapping(address => mapping( uint => uint)) public investorVotes;

    function VotingSprint(uint _durationDays, uint256[] _projectsIds, address _token, address _freezer) public {
        freezer = BalanceFreezer(_freezer);
        token = SmartValleyToken(_token);

        startDate = now;
        endDate = startDate + _durationDays * 1 days;
        projectIds = _projectsIds;
        
        for (uint i = 0; i < _projectsIds.length; i++) {
            projects[_projectsIds[i]] = true;
        }
    }

    function getSprintInformation() external view returns(uint _startDate, uint _endDate, uint _acceptanceThreshold, uint _maximumScore, uint256[] _projectsIds) {        
        _startDate = startDate;
        _endDate = endDate;
        _acceptanceThreshold = acceptanceThreshold;
        _maximumScore = maximumScore;
        _projectsIds = projectIds;
    }

    function getInvestorInformation(address _investorAddress) external view returns(uint256 _tokenAmount, uint256[] _projectsIds) {        
        _tokenAmount = investorTokenAmounts[_investorAddress];       
        _projectsIds = projectInvestorVotes[_investorAddress];
    }

    function getInvestorProjectVote(address _investorAddress, uint256 projectId) external view returns(uint256 _votes) {        
        _votes = investorVotes[_investorAddress][projectId];
    }

    function submitVote(uint _externalId, uint _valueWithDecimals) external {
        require(_valueWithDecimals > 0 && projects[_externalId] && investorVotes[msg.sender][_externalId] == 0 && token.getAvailableBalance(msg.sender) >= _valueWithDecimals);

        if (investorTokenAmounts[msg.sender] == 0) {
            investorTokenAmounts[msg.sender] = _valueWithDecimals;
            freezer.freeze(_valueWithDecimals, (endDate - startDate) / 1 days);
            maximumScore += _valueWithDecimals;
        }

        projectInvestorVotes[msg.sender].push(_externalId);
        investorVotes[msg.sender][_externalId] = _valueWithDecimals;
        projectVotes[_externalId] += _valueWithDecimals;
    }

    function isAccepted(uint _externalId) external constant returns(bool) {
        require(projects[_externalId]);
        return percent(projectVotes[_externalId], maximumScore, 2) >= acceptanceThreshold;
    }

    function percent(uint numerator, uint denominator, uint precision) private pure returns(uint quotient) {
        uint _numerator = numerator * 10 ** (precision+1);
        uint _quotient = ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
    }

    function setAcceptanceThreshold(uint _value) external onlyOwner {
        require(_value > 0);
        acceptanceThreshold = _value;
    }
}