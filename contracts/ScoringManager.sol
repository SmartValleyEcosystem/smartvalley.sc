pragma solidity ^ 0.4.18;

import "./Owned.sol";
import "./Scoring.sol";
import "./VotingSprint.sol";
import "./ScoringExpertsManager.sol";
import "./AdministratorsRegistry.sol";

contract ScoringManager is Owned {
    ScoringExpertsManager public scoringExpertsManager;

    mapping(uint => uint) public estimateRewardsInAreaMap;
    mapping(uint => uint) public areaMaxScoresMap;
    mapping(uint => uint) public questionWeightsMap;

    address[] public scorings;
    mapping(uint256 => address) public scoringsMap;

    AdministratorsRegistry private administratorsRegistry;

    function ScoringManager(address _scoringExpertsManagerAddress, address _administratorsRegistryAddress, uint[] _areas, uint[] _areaEstimateRewardsWEI, uint[] _areaMaxScores) public {
        require(_areas.length == _areaEstimateRewardsWEI.length);

        setAdministratorsRegistry(_administratorsRegistryAddress);
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
        require(_areas.length == _areaExpertCounts.length);

        var scoringCost = getScoringCost(_areas, _areaExpertCounts);
        require(msg.value == scoringCost);
        
        uint[] memory rewards = new uint[](_areas.length);
        uint[] memory areaMaxScores = new uint[](_areas.length);
        for (uint i = 0; i < _areas.length; i++) {
            rewards[i] = estimateRewardsInAreaMap[_areas[i]];
            areaMaxScores[i] = areaMaxScoresMap[_areas[i]];
        }

        Scoring scoring = new Scoring(msg.sender, _areas, _areaExpertCounts, rewards, areaMaxScores);
        scorings.push(scoring);
        scoringsMap[_projectId] = scoring;

        scoringExpertsManager.selectExperts(_projectId, _areas, _areaExpertCounts);

        scoring.transfer(msg.value);
    }

    function startForFree(uint _projectId, address _votingSpringAddress, uint[] _areas, uint[] _areaExpertCounts) external {
        require(_areas.length == _areaExpertCounts.length);
        require(VotingSprint(_votingSpringAddress).isAccepted(_projectId));

        uint[] memory rewards = new uint[](_areas.length);

        for (uint i = 0; i < _areas.length; i++) {
            rewards[i] = estimateRewardsInAreaMap[_areas[i]];
        }

        uint[] memory areaMaxScores = new uint[](_areas.length);
        for (uint j = 0; j < _areas.length; j++) {
            areaMaxScores[j] = areaMaxScoresMap[_areas[j]];
        }

        Scoring scoring = new Scoring(msg.sender, _areas, _areaExpertCounts, rewards, areaMaxScores);
        scorings.push(scoring);
        scoringsMap[_projectId] = scoring;

        scoringExpertsManager.selectExperts(_projectId, _areas, _areaExpertCounts);

        var scoringCost = getScoringCost(_areas, _areaExpertCounts);
        scoring.transfer(scoringCost);
    }

    function submitEstimates(uint _projectId, uint _area, bytes32 _conclusionHash, uint[] _questionIds, uint[] _scores, bytes32[] _commentHashes) external {
        require(_questionIds.length == _scores.length && _scores.length == _commentHashes.length);
        require(scoringExpertsManager.isExpertAssignedToProject(msg.sender, _projectId, _area));

        uint[] memory questionWeights = new uint[](_questionIds.length);
        for (uint i = 0; i < _questionIds.length; i++) {
            questionWeights[i] = questionWeightsMap[_questionIds[i]];
        }

        Scoring scoring = Scoring(scoringsMap[_projectId]);
        scoring.submitEstimates(msg.sender, _area, _conclusionHash, _questionIds, questionWeights, _scores, _commentHashes);
    }

    function setQuestions(uint[] _questionIds, uint[] _weights) external onlyOwner {
        require(_questionIds.length == _weights.length);

        for (uint i = 0; i < _questionIds.length; i++) {
            questionWeightsMap[_questionIds[i]] = _weights[i];
        }
    }

    function updateScoringsOwner(uint _startIndex, uint _count, address _newScoringManager) external {
        require(_startIndex + _count <= scorings.length && _newScoringManager != 0);

        for (uint i = _startIndex; i < _startIndex + _count; i++) {
            Scoring scoring = Scoring(scorings[i]);
            scoring.changeOwner(_newScoringManager);
        }
    } 

    function confirmScoringsOwner(uint _startIndex, uint _count) external {
        require(_startIndex + _count <= scorings.length);

        for (uint i = _startIndex; i < _startIndex + _count; i++) {
            Scoring scoring = Scoring(scorings[i]);
            scoring.confirmOwner();
        }
    }
    
    function setScoringExpertsManager(address _scoringExpertsManagerAddress) public onlyOwner {
        require(_scoringExpertsManagerAddress != 0);
        scoringExpertsManager = ScoringExpertsManager(_scoringExpertsManagerAddress);
    }

    function setAdministratorsRegistry(address _administratorsRegistryAddress) public onlyOwner {
        require(_administratorsRegistryAddress != 0);
        administratorsRegistry = AdministratorsRegistry(_administratorsRegistryAddress);
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
            var reward = estimateRewardsInAreaMap[_areas[i]];
            cost += reward * _areaExpertCounts[i];
        }
        return cost;
    }
}
