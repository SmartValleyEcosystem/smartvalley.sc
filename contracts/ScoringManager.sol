pragma solidity ^ 0.4.18;

import "./Owned.sol";
import "./Scoring.sol";
import "./VotingSprint.sol";
import "./SmartValleyToken.sol";
import "./Minter.sol";

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
    Minter public minter;
    uint public scoringCreationCostWEI;
    uint public estimateRewardWEI;

    function ScoringManager(address _svtAddress, uint _scoringCreationCost, uint _estimateReward, address _minterAddress) public {
        setTokenAddress(_svtAddress);
        setScoringCreationCost(_scoringCreationCost);
        setEstimateReward(_estimateReward);
        setMinterAddress(_minterAddress);
    }

    function start(uint256 _externalId) external {
        require(svt.balanceOf(msg.sender) >= scoringCreationCostWEI);
        Scoring scoring = new Scoring(msg.sender, svt, estimateRewardWEI);
        scorings.push(scoring);
        scoringsMap[_externalId] = scoring;
        svt.transferFromOrigin(scoring, scoringCreationCostWEI);
    }  

    function startForFree(uint256 _externalId, address _votingSpringAddress) external {
        var isAccepted = VotingSprint(_votingSpringAddress).isAccepted(_externalId);
        require(isAccepted);

        Scoring scoring = new Scoring(msg.sender, svt, estimateRewardWEI);
        scorings.push(scoring);
        scoringsMap[_externalId] = scoring;

        minter.mintTokens(scoring, scoringCreationCostWEI);
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

    function updateScoringsOwner(uint _startIndex, uint _count, address _newScoringManager) external {
        require(_startIndex + _count <= scorings.length && _newScoringManager != 0);

        for (var i = _startIndex; i < _startIndex + _count; i++) {
            var scoring = Scoring(scorings[i]);
            scoring.changeOwner(_newScoringManager);
        }
    } 

    function confirmScoringsOwner(uint _startIndex, uint _count) external {
        require(_startIndex + _count <= scorings.length);

        for (var i = _startIndex; i < _startIndex + _count; i++) {
            var scoring = Scoring(scorings[i]);
            scoring.confirmOwner();
        }
    }  

    function updateScoringsSvtAddress(uint _startIndex, uint _count, address _newSvtAddress) external onlyOwner {
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

    function setMinterAddress(address _minterAddress) public onlyOwner {
        require(_minterAddress != 0);
        minter = Minter(_minterAddress);
    }

    function setScoringCreationCost(uint _scoringCreationCost) public onlyOwner {
        scoringCreationCostWEI = _scoringCreationCost * (10 ** uint(svt.decimals()));
    }

    function setEstimateReward(uint _estimateReward) public onlyOwner {
        estimateRewardWEI = _estimateReward * (10 ** uint(svt.decimals()));
    }
}
