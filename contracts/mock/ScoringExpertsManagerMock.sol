pragma solidity ^ 0.4.18;

import "../ScoringExpertsManager.sol";

contract ScoringExpertsManagerMock is ScoringExpertsManager {
    function ScoringExpertsManagerMock(uint _expertsCountMultiplier, uint _offerExpirationPeriodDays, address _expertsRegistryAddress, address _administratorsRegistryAddress) public ScoringExpertsManager(_expertsCountMultiplier, _offerExpirationPeriodDays, _expertsRegistryAddress, _administratorsRegistryAddress) {
    }
}