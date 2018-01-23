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
    mapping(uint => uint) public projectTokenAmounts;
    mapping(address => uint[]) public projectsByInvestor;
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

    function getDetails() external view returns(uint _startDate, uint _endDate, uint _acceptanceThreshold, uint _maximumScore, uint256[] _projectsIds) {        
        _startDate = startDate;
        _endDate = endDate;
        _acceptanceThreshold = acceptanceThreshold;
        _maximumScore = maximumScore;
        _projectsIds = projectIds;
    }

    function getInvestorVotes(address _investorAddress) external view returns(uint256 _tokenAmount, uint256[] _projectsIds) {        
        _tokenAmount = investorTokenAmounts[_investorAddress];       
        _projectsIds = projectsByInvestor[_investorAddress];
    }

    function getVote(address _investorAddress, uint256 projectId) external view returns(uint256 _tokenAmount) {        
        _tokenAmount = investorVotes[_investorAddress][projectId];
    }

    function submitVote(uint _projectId, uint _tokenAmount) external {
        require(_tokenAmount > 0 && projects[_projectId] && investorVotes[msg.sender][_projectId] == 0 && token.getAvailableBalance(msg.sender) >= _tokenAmount);

        if (investorTokenAmounts[msg.sender] == 0) {
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
        return percent(projectTokenAmounts[_externalId], maximumScore, 2) >= acceptanceThreshold;
    }

    function percent(uint _numerator, uint _denominator, uint _precision) private pure returns(uint) {
        return ((_numerator * 10 ** (_precision + 1) / _denominator) + 5) / 10;
    }

    function setAcceptanceThreshold(uint _value) external onlyOwner {
        require(_value > 0);
        acceptanceThreshold = _value;
    }
}