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

    uint public scoringCostWEI;
    uint public estimateRewardWEI;

    mapping(uint => Question) public questionsMap;

    address[] public scorings;
    mapping(uint256 => address) public scoringsMap;

    function ScoringManager(uint _scoringCost, uint _estimateReward, address _scoringExpertsManagerAddress) public {        
        setScoringCost(_scoringCost);
        setEstimateReward(_estimateReward);        
        setScoringExpertsManager(_scoringExpertsManagerAddress);
    }

    function start(uint _projectId, uint[] _areas, uint[] _areaExpertCounts) payable external {
        require(msg.value >= scoringCostWEI);
        require(_areas.length == _areaExpertCounts.length);

        Scoring scoring = new Scoring(msg.sender, _areas, _areaExpertCounts);
        scorings.push(scoring);
        scoringsMap[_projectId] = scoring;

        scoringExpertsManager.selectExperts(_projectId, _areas, _areaExpertCounts);

        scoring.transfer(msg.value);
    }

    function startForFree(uint _projectId, address _votingSpringAddress, uint[] _areas, uint[] _areaExpertCounts) external {
        require(_areas.length == _areaExpertCounts.length);
        require(VotingSprint(_votingSpringAddress).isAccepted(_projectId));

        Scoring scoring = new Scoring(msg.sender, _areas, _areaExpertCounts);
        scorings.push(scoring);
        scoringsMap[_projectId] = scoring;

        scoringExpertsManager.selectExperts(_projectId, _areas, _areaExpertCounts);

        scoring.transfer(scoringCostWEI);       
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
        scoring.submitEstimates(msg.sender, _area, _questionIds, _scores, _commentHashes, estimateRewardWEI);
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

    function setScoringCost(uint _scoringCost) public onlyOwner {
        scoringCostWEI = _scoringCost * 1 ether;
    }

    function setEstimateReward(uint _estimateReward) public onlyOwner {
        estimateRewardWEI = _estimateReward * 1 ether;
    }
}
