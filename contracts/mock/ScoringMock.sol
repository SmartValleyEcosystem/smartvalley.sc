pragma solidity ^ 0.4.23;

import "../Scoring.sol";

contract ScoringMock is Scoring {
    constructor(uint[] _areas, uint[] _areaEstimateRewardsWEI, uint[] _areaMaxScores) Scoring (0x0, _areas, _areaEstimateRewardsWEI, _areaMaxScores) public {
    }
}