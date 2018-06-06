pragma solidity ^ 0.4.24;

import "./ScoringManagerBase.sol";
import "./Scoring.sol";

contract ScoringManager is ScoringManagerBase {
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

    function start(uint _projectId, uint[] _areas, uint[] _areaExpertCounts) payable external {
        require(_areas.length == _areaExpertCounts.length, "_areas and _areaExpertCounts sizes don't match");
        require(scoringsRegistry.getScoringAddressById(_projectId) == 0, "scoring for specified project already exists");
        require(msg.value == getScoringCost(_areas, _areaExpertCounts));

        Scoring scoring = new Scoring(address(scoringParametersProvider)); 
        scoringsRegistry.addScoring(address(scoring), _projectId, _areas, _areaExpertCounts);

        scoringOffersManager.generate(_projectId, _areas);

        address(scoring).transfer(msg.value);
    }

    function getScoringCost(uint[] _areas, uint[] _areaExpertCounts) private view returns(uint) {
        uint cost = 0;
        for (uint i = 0; i < _areas.length; i++) {
            uint reward = scoringParametersProvider.getAreaReward(_areas[i]);
            cost += reward * _areaExpertCounts[i];
        }
        return cost;
    }

    function migrateScorings(uint _startIndex, uint _count) external onlyOwner {
        uint scoringsCount = scoringsRegistry.getScoringsCount();
        require(_startIndex + _count <= scoringsCount);

        for (uint i = _startIndex; i < _startIndex + _count; i++) {
            uint projectId = scoringsRegistry.getProjectIdByIndex(i);
            Scoring scoring = new Scoring(address(scoringParametersProvider));
            scoringsRegistry.setScoringAddress(projectId, address(scoring));
        }
    }
}