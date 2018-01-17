pragma solidity ^ 0.4.18;

import "./Owned.sol";
import "./Scoring.sol";
import "./SmartValleyToken.sol";

contract ScoringManager is Owned {
    struct Question {
        int minScore;
        int maxScore;
    }

    mapping(uint => mapping(uint => Question)) public questionsByArea;
    mapping(address => mapping(uint => mapping(address => bool))) public scoredProjectsByArea;
    address[] public scorings;
    mapping(uint256 => address) public scoringsMap;
    SmartValleyToken public svt;
    uint public scoringCreationCostWEI;
    uint public estimateRewardWEI;


    function ScoringManager(address _svtAddress, uint _scoringCreationCost, uint _estimateReward) public {
        setTokenAddress(_svtAddress);
        setScoringCreationCost(_scoringCreationCost);
        setEstimateReward(_estimateReward);     
    }

    function start(uint256 _externalId) external {
        require(svt.balanceOf(msg.sender) >= scoringCreationCostWEI);
        Scoring scoring = new Scoring(msg.sender, svt, estimateRewardWEI);
        scorings.push(scoring);
        scoringsMap[_externalId] = scoring;
        svt.transferFromOrigin(scoring, scoringCreationCostWEI);
    }  

    function submitEstimates(address _scoringAddress, uint _expertiseArea, uint[] _questionIds, int[] _scores, bytes32[] _commentHashes) external {
        require(_questionIds.length == _scores.length && _scores.length == _commentHashes.length);

        for (uint i = 0; i < _questionIds.length; i++) {
            var question = questionsByArea[_expertiseArea][_questionIds[i]];
            require(question.minScore != question.maxScore);
            require(_scores[i] <= question.maxScore && _scores[i] >= question.minScore);
        }

        require(!scoredProjectsByArea[msg.sender][_expertiseArea][_scoringAddress]);

        scoredProjectsByArea[msg.sender][_expertiseArea][_scoringAddress] = true;

        Scoring scoring = Scoring(_scoringAddress);
        scoring.submitEstimates(msg.sender, _expertiseArea, _questionIds, _scores, _commentHashes);
    }

    function setQuestions(uint[] _expertiseAreas, uint[] _questionIds, int[] _minScores, int[] _maxScores) external onlyOwner {
        require(_expertiseAreas.length == _questionIds.length && _questionIds.length == _minScores.length && _minScores.length == _maxScores.length);

        for (uint i = 0; i < _questionIds.length; i++) {
            questionsByArea[_expertiseAreas[i]][_questionIds[i]] = Question(_minScores[i], _maxScores[i]);
        }
    }

    function updateScoringsManagerAddress(uint _startIndex, uint _count, address _newScoringManager) public onlyOwner {
        require(_startIndex + _count <= scorings.length && _newScoringManager != 0);

        for (var i = _startIndex; i < _startIndex + _count; i++) {
            var scoring = Scoring(scorings[i]);
            scoring.setScoringManagerAddress(_newScoringManager);
        }
    }  

    function updateScoringsSvtAddress(uint _startIndex, uint _count, address _newSvtAddress) public onlyOwner {
        require(_startIndex + _count <= scorings.length && _newSvtAddress != 0);

        for (var i = _startIndex; i < _startIndex + _count; i++) {
            var scoring = Scoring(scorings[i]);
            scoring.setTokenAddress(_newSvtAddress);
        }
    }

    function setTokenAddress(address _svtAddress) public onlyOwner {
        require(_svtAddress != 0);
        svt = SmartValleyToken(_svtAddress);
    }

    function setScoringCreationCost(uint _scoringCreationCost) public onlyOwner {
        scoringCreationCostWEI = _scoringCreationCost * (10 ** uint(svt.decimals()));
    }

    function setEstimateReward(uint _estimateReward) public onlyOwner {
        estimateRewardWEI = _estimateReward * (10 ** uint(svt.decimals()));
    }  
}
