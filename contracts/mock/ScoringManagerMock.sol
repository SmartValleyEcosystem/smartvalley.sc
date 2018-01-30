pragma solidity ^ 0.4.18;

import "../ScoringManager.sol";

contract ScoringManagerMock  is ScoringManager {

    function ScoringManagerMock (address _svtAddress, uint _scoringCreationCost, uint _estimateReward, address _minterAddress) ScoringManager (_svtAddress, _scoringCreationCost, _estimateReward, _minterAddress) public {
    }
}