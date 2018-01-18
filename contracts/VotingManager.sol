pragma solidity ^ 0.4.18;

import "./Owned.sol";
import "./VotingSprint.sol";

contract VotingManager is Owned {

    VotingSprint public lastSprint;
    VotingSprint[] public sprints;
    uint public minimumProjectsCount;

    BalanceFreezer public freezer;
    SmartValleyToken public token;

    uint256[] public projectsQueue;
    
    function VotingManager(address _freezer, address _token) public {
        require(_freezer != 0 && _token != 0);

        freezer = BalanceFreezer(_freezer);
        token = SmartValleyToken(_token);
    }

    function enqueueProject(uint _projectId) external {
        for (uint i = 0; i < projectsQueue.length; i++) {
            require(projectsQueue[i] != _projectId);
        }

        projectsQueue.push(_projectId);
    }

    function createSprint(uint _durationDays) public onlyOwner {
        require(_durationDays > 0 && (lastSprint == address(0) || lastSprint.endDate() <= now) && projectsQueue.length >= minimumProjectsCount);        
        var newSprint = new VotingSprint(_durationDays, projectsQueue, token, freezer);
        sprints.push(newSprint);
        lastSprint = newSprint;
        projectsQueue.length = 0;
    }

    function setMinimumProjectsCount (uint _value) public onlyOwner {
        require(_value > 0);
        minimumProjectsCount = _value;
    }

    function setAcceptanceThreshold (uint _value) public onlyOwner {
        require(_value > 0 && lastSprint != address(0));
        lastSprint.setAcceptanceThreshold(_value);
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
