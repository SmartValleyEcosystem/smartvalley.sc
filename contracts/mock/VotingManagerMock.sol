pragma solidity ^ 0.4.22;

import "../VotingManager.sol";
import "../mock/VotingSprintMock.sol";

contract VotingManagerMock is VotingManager {
    constructor(address _freezer, address _token, uint _minimumProjectsCount) VotingManager(_freezer, _token, _minimumProjectsCount) public {
    }

    function createSprint(uint _durationDays) public onlyOwner {
        require(_durationDays > 0 && (lastSprint == address(0) || lastSprint.endDate() <= now) && projectsQueue.length >= minimumProjectsCount);

        uint newSprintNumber = sprints.length + 1;
        VotingSprintMock newSprint = new VotingSprintMock(newSprintNumber, _durationDays, projectsQueue, acceptanceThresholdPercent, token, freezer);
        sprints.push(newSprint);
        lastSprint = newSprint;
        projectsQueue.length = 0;
    }
}