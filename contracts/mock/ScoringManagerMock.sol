pragma solidity ^ 0.4.24;

import "../ScoringManager.sol";

contract ScoringManagerMock is ScoringManager {
    constructor(
        address _scoringOffersManagerAddress,
        address _administratorsRegistryAddress,
        address _scoringsRegistryAddress,
        address _scoringParametersProviderAddress)
        ScoringManager(
            _scoringOffersManagerAddress,
            _administratorsRegistryAddress,
            _scoringsRegistryAddress,
            _scoringParametersProviderAddress) public {
    }
}