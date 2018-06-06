pragma solidity ^ 0.4.24;

import "../ScoringOffersManager.sol";

contract ScoringOffersManagerMock is ScoringOffersManager {
    constructor(
        uint _expertsCountMultiplier,
        uint _offerExpirationPeriodDays,
        uint _scoringExpirationPeriodDays,
        address _expertsRegistryAddress,
        address _administratorsRegistryAddress,
        address _scoringsRegistryAddress)
        ScoringOffersManager(
            _expertsCountMultiplier,
            _offerExpirationPeriodDays,
            _scoringExpirationPeriodDays,
            _expertsRegistryAddress,
            _administratorsRegistryAddress,
            _scoringsRegistryAddress) public {
    }
}