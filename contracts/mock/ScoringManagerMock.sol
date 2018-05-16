pragma solidity ^ 0.4.23;

import "../ScoringManager.sol";

contract ScoringManagerMock is ScoringManager {
    constructor(address _scoringExpertsManagerAddress, address _administratorsRegistryAddress, address _scoringsRegistryAddress, uint[] _areas, uint[] _areaEstimateRewardsWEI, uint[] _areaMaxScores) ScoringManager ( _scoringExpertsManagerAddress, _administratorsRegistryAddress, _scoringsRegistryAddress, _areas, _areaEstimateRewardsWEI, _areaMaxScores) public {
    }
}