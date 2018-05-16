pragma solidity ^ 0.4.23;

import "../ScoringExpertsManager.sol";

contract ScoringExpertsManagerMock is ScoringExpertsManager {
    constructor(uint _expertsCountMultiplier, uint _offerExpirationPeriodDays, uint _scoringExpirationPeriodDays, address _expertsRegistryAddress, address _administratorsRegistryAddress, address _scoringsRegistryAddress) public ScoringExpertsManager(_expertsCountMultiplier, _offerExpirationPeriodDays, _scoringExpirationPeriodDays, _expertsRegistryAddress, _administratorsRegistryAddress, _scoringsRegistryAddress) {
    }
}