pragma solidity ^ 0.4.24;

import "./ScoringManagerBase.sol";
import "./PrivateScoring.sol";

contract PrivateScoringManager is ScoringManagerBase {

    constructor(
        address _scoringOffersManagerAddress,
        address _administratorsRegistryAddress,
        address _scoringsRegistryAddress,
        address _scoringParametersProviderAddress)
        ScoringManagerBase(
            _scoringOffersManagerAddress,
            _administratorsRegistryAddress,
            _scoringsRegistryAddress,
            _scoringParametersProviderAddress) public {
    }

    function start(uint _projectId, uint[] _expertAreas, address[] _experts) external onlyAdministrators {
        require(_expertAreas.length == _experts.length, "_areas and _experts sizes don't match");
        require(scoringsRegistry.getScoringAddressById(_projectId) == 0, "scoring for specified project already exists");

        uint[] memory areas = scoringParametersProvider.getAreas();
        PrivateScoring scoring = new PrivateScoring(address(scoringParametersProvider));
        scoringsRegistry.addScoring(address(scoring), _projectId, areas, new uint[](areas.length));

        scoringOffersManager.set(_projectId, _expertAreas, _experts);
    }
}