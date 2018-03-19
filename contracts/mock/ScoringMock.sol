pragma solidity ^ 0.4.18;

import "../Scoring.sol";

contract ScoringMock is Scoring {
    function ScoringMock(uint[] _areas, uint[] _areaExpertCounts, uint[] _areaEstimateRewardsWEI) Scoring (0x0, _areas, _areaExpertCounts, _areaEstimateRewardsWEI) public {
    }
}