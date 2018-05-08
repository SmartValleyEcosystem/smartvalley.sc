pragma solidity ^ 0.4.22;

import "../Scoring.sol";

contract ScoringMock is Scoring {
    constructor(uint[] _areas, uint[] _areaExpertCounts, uint[] _areaEstimateRewardsWEI, uint[] _areaMaxScores) Scoring (0x0, _areas, _areaExpertCounts, _areaEstimateRewardsWEI, _areaMaxScores) public {
    }
}