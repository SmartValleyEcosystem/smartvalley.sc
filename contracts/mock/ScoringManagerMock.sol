pragma solidity ^ 0.4.18;

import "../ScoringManager.sol";

contract ScoringManagerMock  is ScoringManager {
    function ScoringManagerMock (address _tokenAddress, uint _scoringCreationCost, uint _estimateReward, address _minterAddress, address _scoringExpertsManagerAddress) ScoringManager (_tokenAddress, _scoringCreationCost, _estimateReward, _minterAddress, _scoringExpertsManagerAddress) public {
    }
}