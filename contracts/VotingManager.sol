pragma solidity ^ 0.4.22;

import "./Owned.sol";
import "./VotingSprint.sol";

contract VotingManager is Owned {

    VotingSprint public lastSprint;
    VotingSprint[] public sprints;

    uint public minimumProjectsCount;
    uint public acceptanceThresholdPercent;

    BalanceFreezer public freezer;
    SmartValleyToken public token;

    uint256[] public projectsQueue;

    constructor(address _freezer, address _token, uint _minimumProjectsCount) public {
        require(_freezer != 0 && _token != 0);
        freezer = BalanceFreezer(_freezer);
        token = SmartValleyToken(_token);
        setMinimumProjectsCount(_minimumProjectsCount);
    }

     function getProjectsQueue() external view returns(uint[] _projectsQueue) {
       _projectsQueue = projectsQueue;
    }

     function getSprints() external view returns(VotingSprint[] _sprints) {
        _sprints = sprints;
    }

    function enqueueProject(uint _projectId) external {
        for (uint i = 0; i < projectsQueue.length; i++) {
            require(projectsQueue[i] != _projectId);
        }

        projectsQueue.push(_projectId);
    }

    function createSprint(uint _durationDays) public onlyOwner {
        require(_durationDays > 0 && (lastSprint == address(0) || lastSprint.endDate() <= now) && projectsQueue.length >= minimumProjectsCount);
        uint newSprintNumber = sprints.length + 1;
        VotingSprint newSprint = new VotingSprint(newSprintNumber, _durationDays, projectsQueue, acceptanceThresholdPercent, token, freezer);
        sprints.push(newSprint);
        lastSprint = newSprint;
        projectsQueue.length = 0;
    }

    function setMinimumProjectsCount (uint _value) public onlyOwner {
        require(_value > 0);
        minimumProjectsCount = _value;
    }

    function setAcceptanceThresholdPercent (uint _value) public onlyOwner {
        require(_value > 0);
        acceptanceThresholdPercent = _value;
        if (lastSprint != address(0)) {
            lastSprint.setAcceptanceThresholdPercent(_value);
        }
    }

    function setFreezerAddress (address _freezerAddress) public onlyOwner {
        require(_freezerAddress != 0);
        freezer = BalanceFreezer(_freezerAddress);
    }

    function setTokenAddress (address _tokenAddress) public onlyOwner {
        require(_tokenAddress != 0);
        token = SmartValleyToken(_tokenAddress);
    }
}
