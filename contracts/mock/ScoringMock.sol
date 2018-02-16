pragma solidity ^ 0.4.18;

import "../Scoring.sol";

contract ScoringMock is Scoring {
    function ScoringMock(address _svtAddress, uint[] _areas, uint[] _areaExpertCounts) Scoring (0x0, _svtAddress, _areas, _areaExpertCounts) public {
    }
}