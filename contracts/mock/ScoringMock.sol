pragma solidity ^ 0.4.24;

import "../Scoring.sol";

contract ScoringMock is Scoring {
    constructor(address _scoringParametersProviderAddress) Scoring (0x0, _scoringParametersProviderAddress) public {
    }
}