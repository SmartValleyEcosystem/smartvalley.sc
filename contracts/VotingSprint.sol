pragma solidity ^ 0.4.18;

import "./Owned.sol";
import "./BalanceFreezer.sol";
import "./SmartValleyToken.sol";

contract VotingSprint is Owned {

    uint public number;
    uint public startDate;
    uint public endDate;
    uint public acceptanceThresholdPercent;
    uint public maximumScore;
    uint[] public projectIds;

    BalanceFreezer public freezer;
    SmartValleyToken public token;

    mapping(uint => bool) public projects;
    mapping(uint => uint) public projectTokenAmounts;
    mapping(address => uint[]) public projectsByInvestor;
    mapping(address => uint) public investorTokenAmounts;
    mapping(address => mapping( uint => uint)) public investorVotes;

    function VotingSprint(uint _number, uint _durationDays, uint256[] _projectsIds, uint _acceptanceThresholdPercent, address _token, address _freezer) public {
        freezer = BalanceFreezer(_freezer);
        token = SmartValleyToken(_token);

        number = _number;
        startDate = now;
        endDate = startDate + _durationDays * 1 days;
        projectIds = _projectsIds;
        acceptanceThresholdPercent = _acceptanceThresholdPercent;
        
        for (uint i = 0; i < _projectsIds.length; i++) {
            projects[_projectsIds[i]] = true;
        }
    }

    function getDetails() external view returns(uint _startDate, uint _endDate, uint _acceptanceThresholdPercent, uint _maximumScore, uint256[] _projectsIds, uint _number) {
        _startDate = startDate;
        _endDate = endDate;
        _acceptanceThresholdPercent = acceptanceThresholdPercent;
        _maximumScore = maximumScore;
        _projectsIds = projectIds;
        _number = number;
    }

    function getInvestorVotes(address _investorAddress) external view returns(uint256 _tokenAmount, uint256[] _projectsIds) {
        _tokenAmount = investorTokenAmounts[_investorAddress];
        _projectsIds = projectsByInvestor[_investorAddress];
    }

    function getVote(address _investorAddress, uint256 projectId) external view returns(uint256 _tokenAmount) {
        _tokenAmount = investorVotes[_investorAddress][projectId];
    }

    function submitVote(uint _projectId, uint _tokenAmount) external {
        require(_tokenAmount > 0 && projects[_projectId] && investorVotes[msg.sender][_projectId] == 0);

        if (investorTokenAmounts[msg.sender] == 0) {
            require(token.getAvailableBalance(msg.sender) >= _tokenAmount);

            investorTokenAmounts[msg.sender] = _tokenAmount;
            freezer.freeze(_tokenAmount, (endDate - startDate) / 1 days);
            maximumScore += _tokenAmount;
        }

        projectsByInvestor[msg.sender].push(_projectId);
        investorVotes[msg.sender][_projectId] = _tokenAmount;
        projectTokenAmounts[_projectId] += _tokenAmount;
    }

    function isAccepted(uint _externalId) external constant returns(bool) {
        require(projects[_externalId]);
        return (projectTokenAmounts[_externalId] * 100) / maximumScore >= acceptanceThresholdPercent;
    }    

    function setAcceptanceThresholdPercent(uint _value) external onlyOwner {
        require(_value > 0);
        acceptanceThresholdPercent = _value;
    }
}