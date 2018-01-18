pragma solidity ^ 0.4.18;

import "../ScoringManager.sol";

contract ScoringManagerMock  is ScoringManager {

    function ScoringManagerMock (address _svtAddress, uint _scoringCreationCost, address _minterAddress) ScoringManager (_svtAddress, _scoringCreationCost, 10, _minterAddress) public {
    }
}