pragma solidity ^ 0.4.18;

import "../VotingSprint.sol";

contract VotingSprintMock is VotingSprint {
    function VotingSprintMock(uint _number, uint _durationDays, uint256[] _projectsIds, uint _acceptanceThreshold, address _token, address _freezer) VotingSprint(_number, _durationDays, _projectsIds, _acceptanceThreshold, _token, _freezer) public { 
    }

    function rewindTime(uint _days) external {
        startDate = startDate + _days * 1 days;
        endDate = endDate + _days * 1 days;
    }
}
