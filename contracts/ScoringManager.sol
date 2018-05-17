pragma solidity ^ 0.4.23;

import "./Owned.sol";
import "./Scoring.sol";
import "./ScoringExpertsManager.sol";
import "./AdministratorsRegistry.sol";
import "./ScoringsRegistry.sol";

contract ScoringManager is Owned {

    ScoringExpertsManager public scoringExpertsManager;
    ScoringsRegistry public scoringsRegistry;
    AdministratorsRegistry public administratorsRegistry;

    mapping(uint => uint) public estimateRewardsInAreaMap;
    mapping(uint => uint) public areaMaxScoresMap;
    mapping(uint => uint) public questionWeightsMap;

    constructor(address _scoringExpertsManagerAddress,
                address _administratorsRegistryAddress,
                address _scoringsRegistryAddress,
                uint[] _areas,
                uint[] _areaEstimateRewardsWEI,
                uint[] _areaMaxScores) public {
        require(_areas.length == _areaEstimateRewardsWEI.length);

        setAdministratorsRegistry(_administratorsRegistryAddress);
        setScoringsRegistry(_scoringsRegistryAddress);
        setScoringExpertsManager(_scoringExpertsManagerAddress);

        for (uint i = 0; i < _areas.length; i++) {
            setEstimateRewardInArea(_areas[i], _areaEstimateRewardsWEI[i]);
            setAreaMaxScore(_areas[i], _areaMaxScores[i]);
        }
    }

    modifier onlyAdministrators {
        require(administratorsRegistry.isAdministrator(msg.sender) || msg.sender == owner);
        _;
    }

    function start(uint _projectId, uint[] _areas, uint[] _areaExpertCounts) payable external {
        require(_areas.length == _areaExpertCounts.length, "_areas and _areaExpertCounts sizes don't match");
        require(scoringsRegistry.getScoringAddressById(_projectId) == 0, "scoring for specified project already exists");

        uint scoringCost = getScoringCost(_areas, _areaExpertCounts);
        require(msg.value == scoringCost);

        uint[] memory rewards = new uint[](_areas.length);
        uint[] memory areaMaxScores = new uint[](_areas.length);
        for (uint i = 0; i < _areas.length; i++) {
            rewards[i] = estimateRewardsInAreaMap[_areas[i]];
            areaMaxScores[i] = areaMaxScoresMap[_areas[i]];
        }

        Scoring scoring = new Scoring(msg.sender, _areas, rewards, areaMaxScores); 
        scoringsRegistry.addScoring(address(scoring), _projectId, _areas, _areaExpertCounts, scoringExpertsManager.offerExpirationPeriod());

        scoringExpertsManager.selectExperts(_projectId);

        address(scoring).transfer(msg.value);
    }

    function startPrivate(uint _projectId, uint[] _expertAreas, address[] _experts) external {
        require(_expertAreas.length == _experts.length, "_areas and _experts sizes don't match");
        require(scoringsRegistry.getScoringAddressById(_projectId) == 0, "scoring for specified project already exists");

        uint[] memory areas = distinct(_expertAreas);
        uint[] memory rewards = new uint[](areas.length);
        uint[] memory areaMaxScores = new uint[](areas.length);
        for (uint i = 0; i < areas.length; i++) {
            rewards[i] = estimateRewardsInAreaMap[areas[i]];
            areaMaxScores[i] = areaMaxScoresMap[areas[i]];
        }

        uint[] memory areaExpertCounts = new uint[](areas.length);
        for (uint j = 0; j < _expertAreas.length; j++) {
            uint areaIndex = indexOf(areas, _expertAreas[j]);
            areaExpertCounts[areaIndex]++;
        }

        Scoring scoring = new Scoring(msg.sender, areas, rewards, areaMaxScores); 
        scoringsRegistry.addScoring(address(scoring), _projectId, areas, areaExpertCounts, scoringExpertsManager.offerExpirationPeriod());

        scoringExpertsManager.setExperts(_projectId, _expertAreas, _experts);
    }

    function submitEstimates(uint _projectId, uint _area, bytes32 _conclusionHash, uint[] _questionIds, uint[] _scores, bytes32[] _commentHashes) external {
        require(_questionIds.length == _scores.length && _scores.length == _commentHashes.length);

        scoringExpertsManager.finish(_projectId, _area, msg.sender);

        uint[] memory questionWeights = new uint[](_questionIds.length);
        for (uint i = 0; i < _questionIds.length; i++) {
            questionWeights[i] = questionWeightsMap[_questionIds[i]];
        }

        Scoring scoring = Scoring(scoringsRegistry.getScoringAddressById(_projectId));
        scoring.submitEstimates(msg.sender, _area, _conclusionHash, _questionIds, questionWeights, _scores, _commentHashes);
    }

    function setQuestions(uint[] _questionIds, uint[] _weights) external onlyOwner {
        require(_questionIds.length == _weights.length);

        for (uint i = 0; i < _questionIds.length; i++) {
            questionWeightsMap[_questionIds[i]] = _weights[i];
        }
    }

    function updateScoringsOwner(uint _startIndex, uint _count, address _newScoringManager) external onlyOwner {
        uint scoringsCount = scoringsRegistry.getScoringsCount();
        require(_startIndex + _count <= scoringsCount && _newScoringManager != 0);

        for (uint i = _startIndex; i < _startIndex + _count; i++) {
            Scoring scoring = Scoring(scoringsRegistry.getScoringAddressByIndex(i));
            scoring.changeOwner(_newScoringManager);
        }
    }

    function confirmScoringsOwner(uint _startIndex, uint _count) external {
        uint scoringsAmount = scoringsRegistry.getScoringsCount();
        require(_startIndex + _count <= scoringsAmount);

        for (uint i = _startIndex; i < _startIndex + _count; i++) {
            Scoring scoring = Scoring(scoringsRegistry.getScoringAddressByIndex(i));
            scoring.confirmOwner();
        }
    }

    function setScoringExpertsManager(address _address) public onlyOwner {
        require(_address != 0);
        scoringExpertsManager = ScoringExpertsManager(_address);
    }

    function setAdministratorsRegistry(address _address) public onlyOwner {
        require(_address != 0);
        administratorsRegistry = AdministratorsRegistry(_address);
    }

    function setScoringsRegistry(address _address) public onlyOwner {
        require(_address != 0);
        scoringsRegistry = ScoringsRegistry(_address);
    }

    function setAreaMaxScore(uint _area, uint _value) public onlyOwner {
        require(_value > 0);
        areaMaxScoresMap[_area] = _value;
    }

    function setAreaMaxScores(uint[] _areas, uint[] _values) public onlyOwner {
        require(_areas.length == _values.length);
        for (uint i = 0; i < _areas.length; i++) {
            setAreaMaxScore(_areas[i], _values[i]);
        }
    }

    function setEstimateRewardInArea(uint _area, uint _estimateRewardWEI) public onlyAdministrators {
        require(_estimateRewardWEI > 0);
        estimateRewardsInAreaMap[_area] = _estimateRewardWEI;
    }

    function setEstimateRewards(uint[] _areas, uint[] _estimateRewardsWEI) public onlyAdministrators {
        require(_areas.length == _estimateRewardsWEI.length);
        for (uint i = 0; i < _areas.length; i++) {
            setEstimateRewardInArea(_areas[i], _estimateRewardsWEI[i]);
        }
    }

    function getScoringCost(uint[] _areas, uint[] _areaExpertCounts) private view returns(uint) {
        uint cost = 0;
        for (uint i = 0; i < _areas.length; i++) {
            uint reward = estimateRewardsInAreaMap[_areas[i]];
            cost += reward * _areaExpertCounts[i];
        }
        return cost;
    }

    function indexOf(uint[] _collection, uint _value) private pure returns(uint) {
        for (uint i = 0; i < _collection.length; i++) {
            if (_collection[i] == _value) {
                return i;
            }
        }
        return uint(-1);
    }

    function distinct(uint[] _collection) public pure returns(uint[]) {
        if (_collection.length < 2) {
            return _collection;
        }

        uint map = 0;
        uint max = _collection[0];
        uint uniqueElementsCount = 0;
        for (uint i = 0; i < _collection.length; i++) {
            if (map & 2 ** _collection[i] == 0) {
                map |= 2 ** _collection[i];
                uniqueElementsCount++;

                if (_collection[i] > max) {
                    max = _collection[i];
                }
            }
        }

        uint[] memory result = new uint[](uniqueElementsCount);
        uint resultIndex = 0;
        for (uint j = 0; j <= max; j++) {
            if (map & 2 ** j != 0) {
                result[resultIndex] = j;
                resultIndex++;
            }
        }

        return result;
    }
}
