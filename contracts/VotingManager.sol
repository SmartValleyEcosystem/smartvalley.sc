pragma solidity ^ 0.4.18;

import "./Owned.sol";

contract VotingManager is Owned {

    uint256[] public projectsQueue;

    function enqueueProject(uint _projectId) external {
        for (uint i = 0; i < projectsQueue.length; i++) {
            require(projectsQueue[i] != _projectId);
        }

        projectsQueue.push(_projectId);
    }
}
