pragma solidity ^ 0.4.18;

import "./Owned.sol";
import "./Scoring.sol";
import "./VotingSprint.sol";
import "./ScoringExpertsManager.sol";

contract ScoringManager is Owned {
    struct Question {
        int minScore;
        int maxScore;
    }    
    
    ScoringExpertsManager public scoringExpertsManager;

    mapping(uint => uint) public estimateRewardsInAreaMap;   
    mapping(uint => Question) public questionsMap;

    address[] public scorings;
    mapping(uint256 => address) public scoringsMap;

    function ScoringManager(address _scoringExpertsManagerAddress, uint[] _areas, uint[] _areaEstimateRewardsWEI) public {         
        require(_areas.length == _areaEstimateRewardsWEI.length);  

        setScoringExpertsManager(_scoringExpertsManagerAddress);

        for (uint i = 0; i < _areas.length; i++) {
            require(_areaEstimateRewardsWEI[i] > 0);
            setEstimateRewardInArea(_areas[i], _areaEstimateRewardsWEI[i]); 
        }
    }

    function start(uint _projectId, uint[] _areas, uint[] _areaExpertCounts) payable external {
        require(_areas.length == _areaExpertCounts.length);

        var scoringCost = getScoringCost(_areas, _areaExpertCounts);
        require(msg.value == scoringCost);
        
        uint[] memory rewards = new uint[](_areas.length);

        for (uint i = 0; i < _areas.length; i++) {
            rewards[i] = estimateRewardsInAreaMap[_areas[i]];
        }

        Scoring scoring = new Scoring(msg.sender, _areas, _areaExpertCounts, rewards);
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

        Scoring scoring = new Scoring(msg.sender, _areas, _areaExpertCounts, rewards);
        scorings.push(scoring);
        scoringsMap[_projectId] = scoring;

        scoringExpertsManager.selectExperts(_projectId, _areas, _areaExpertCounts);

        var scoringCost = getScoringCost(_areas, _areaExpertCounts);
        scoring.transfer(scoringCost);       
    }

    function submitEstimates(uint _projectId, uint _area, uint[] _questionIds, int[] _scores, bytes32[] _commentHashes) external {
        require(_questionIds.length == _scores.length && _scores.length == _commentHashes.length);
        require(scoringExpertsManager.isExpertAssignedToProject(msg.sender, _projectId, _area));

        for (uint i = 0; i < _questionIds.length; i++) {
            Question storage question = questionsMap[_questionIds[i]];
            require(question.minScore != question.maxScore);
            require(_scores[i] <= question.maxScore && _scores[i] >= question.minScore);
        }

        Scoring scoring = Scoring(scoringsMap[_projectId]);
        scoring.submitEstimates(msg.sender, _area, _questionIds, _scores, _commentHashes);
    }

    function setQuestions(uint[] _questionIds, int[] _minScores, int[] _maxScores) external onlyOwner {
        require(_questionIds.length == _minScores.length && _minScores.length == _maxScores.length);

        for (uint i = 0; i < _questionIds.length; i++) {
            questionsMap[_questionIds[i]] = Question(_minScores[i], _maxScores[i]);
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

    function setEstimateRewardInArea(uint _area, uint _estimateRewardWEI) public onlyOwner {
        estimateRewardsInAreaMap[_area] = _estimateRewardWEI;
    }

    function getScoringCost(uint[] _areas, uint[] _areaExpertCounts) private returns(uint) {
        uint cost = 0;

        for (uint i = 0; i < _areas.length; i++) {
            var reward = estimateRewardsInAreaMap[_areas[i]];
            cost += reward * _areaExpertCounts[i];           
        }
        return cost;
    }
}
