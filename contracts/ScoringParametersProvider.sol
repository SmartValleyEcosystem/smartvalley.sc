pragma solidity ^ 0.4.24;

import "./Owned.sol";

contract ScoringParametersProvider is Owned {
    struct Area {
        uint id;
        uint maxScore;
        uint reward;
    }

    struct Criterion {
        uint id;
        uint areaId;
        uint weight;
    }

    uint[] public areas;
    mapping(uint => Area) public areasMap;

    uint[] public criteria;
    mapping(uint => Criterion) public criteriaMap;

    function getCriterionWeight(uint _criterionId) external view returns(uint) {
        require(criteriaMap[_criterionId].id != 0, "specified criterion does not exist");
        return criteriaMap[_criterionId].weight;
    }

    function getCriterionArea(uint _criterionId) external view returns(uint) {
        require(criteriaMap[_criterionId].id != 0, "specified criterion does not exist");
        return criteriaMap[_criterionId].areaId;
    }

    function getAreaMaxScore(uint _areaId) external view returns(uint) {
        require(areasMap[_areaId].id != 0, "specified area does not exist");
        return areasMap[_areaId].maxScore;
    }

    function getAreaReward(uint _areaId) external view returns(uint) {
        require(areasMap[_areaId].id != 0, "specified area does not exist");
        return areasMap[_areaId].reward;
    }

    function getAreas() external view returns(uint[]) {
        return areas;
    }

    function doesAreaExist(uint _areaId) public view returns(bool) {
        for (uint i = 0; i < areas.length; i++) {
            if (areas[i] == _areaId) {
                return true;
            }
        }
        return false;
    }

    function initializeAreaParameters(uint _areaId, uint _maxScore, uint _reward, uint[] _criterionIds, uint[] _criterionWeights) external onlyOwner {
        require(!doesAreaExist(_areaId));
        require(_criterionIds.length == _criterionWeights.length);

        areas.push(_areaId);
        areasMap[_areaId] = Area(_areaId, _maxScore, _reward);

        for (uint i = 0; i < _criterionIds.length; i++) {
            criteriaMap[_criterionIds[i]] = Criterion(_criterionIds[i], _areaId, _criterionWeights[i]);
        }
    }
}