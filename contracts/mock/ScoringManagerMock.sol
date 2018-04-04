pragma solidity ^ 0.4.18;

import "../ScoringManager.sol";

contract ScoringManagerMock is ScoringManager {
    function ScoringManagerMock (address _scoringExpertsManagerAddress, uint[] _areas, uint[] _areaEstimateRewardsWEI, uint[] _areaMaxScores) ScoringManager ( _scoringExpertsManagerAddress, _areas, _areaEstimateRewardsWEI, _areaMaxScores) public {
    }
}