pragma solidity ^ 0.4.18;

import "../VotingSprint.sol";
import "../mock/BalanceFreezerMock.sol";

contract VotingSprintMock is VotingSprint {
    function VotingSprintMock(uint _number, uint _durationDays, uint256[] _projectsIds, uint _acceptanceThreshold, address _token, address _freezer) VotingSprint(_number, _durationDays, _projectsIds, _acceptanceThreshold, _token, _freezer) public { 
    }

    function rewindTimeAndInvestors(uint _days, address[] _investors) public {
        for (uint i = 0; i < _investors.length; i++) {   
            BalanceFreezerMock balanceFreezerMock = BalanceFreezerMock(freezer);
            balanceFreezerMock.rewindTime(_investors[i], _days);
        }       
        rewindTime(_days);
    }

    function rewindTime(uint _days) public {
        startDate = startDate + _days * 1 days;
        endDate = endDate + _days * 1 days;
    }
}