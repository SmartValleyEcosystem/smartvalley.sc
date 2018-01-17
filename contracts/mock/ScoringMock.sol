pragma solidity ^ 0.4.18;

import "../Scoring.sol";

contract ScoringMock is Scoring {
    function ScoringMock(address _svtAddress) Scoring (0x0, _svtAddress, 10 * (10 ** 18)) public {
    }
}