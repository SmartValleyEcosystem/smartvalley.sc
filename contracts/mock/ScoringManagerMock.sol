pragma solidity ^ 0.4.18;

import "../ScoringManager.sol";

contract ScoringManagerMock  is ScoringManager {
    function ScoringManagerMock (uint _scoringCreationCost, uint _estimateReward, address _scoringExpertsManagerAddress) ScoringManager (_scoringCreationCost, _estimateReward, _scoringExpertsManagerAddress) public {
    }
}