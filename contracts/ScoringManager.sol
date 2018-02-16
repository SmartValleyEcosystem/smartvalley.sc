pragma solidity ^ 0.4.19;

import "./Owned.sol";
import "./Scoring.sol";
import "./VotingSprint.sol";
import "./SmartValleyToken.sol";
import "./Minter.sol";
import "./ScoringExpertsManager.sol";

contract ScoringManager is Owned {
    struct Question {
        int minScore;
        int maxScore;
    }

    Minter public minter;
    SmartValleyToken public token;
    ScoringExpertsManager public scoringExpertsManager;

    uint public scoringCostWEI;
    uint public estimateRewardWEI;

    mapping(uint => Question) public questionsMap;

    address[] public scorings;
    mapping(uint256 => address) public scoringsMap;

    function ScoringManager(address _tokenAddress, uint _scoringCost, uint _estimateReward, address _minterAddress, address _scoringExpertsManagerAddress) public {
        setToken(_tokenAddress);
        setScoringCost(_scoringCost);
        setEstimateReward(_estimateReward);
        setMinter(_minterAddress);
        setScoringExpertsManager(_scoringExpertsManagerAddress);
    }

    function start(uint _projectId, uint[] _areas, uint[] _areaExpertCounts) external {
        require(token.balanceOf(msg.sender) >= scoringCostWEI);
        require(_areas.length == _areaExpertCounts.length);

        Scoring scoring = new Scoring(msg.sender, token, _areas, _areaExpertCounts);
        scorings.push(scoring);
        scoringsMap[_projectId] = scoring;

        scoringExpertsManager.selectExperts(_projectId, _areas, _areaExpertCounts);

        token.transferFromOrigin(scoring, scoringCostWEI);
    }

    function startForFree(uint _projectId, address _votingSpringAddress, uint[] _areas, uint[] _areaExpertCounts) external {
        require(_areas.length == _areaExpertCounts.length);

        var isAccepted = VotingSprint(_votingSpringAddress).isAccepted(_projectId);
        require(isAccepted);

        Scoring scoring = new Scoring(msg.sender, token, _areas, _areaExpertCounts);
        scorings.push(scoring);
        scoringsMap[_projectId] = scoring;

        scoringExpertsManager.selectExperts(_projectId, _areas, _areaExpertCounts);

        minter.mintTokens(scoring, scoringCostWEI);
    }

    function submitEstimates(uint _projectId, uint _area, uint[] _questionIds, int[] _scores, bytes32[] _commentHashes) external {
        require(_questionIds.length == _scores.length && _scores.length == _commentHashes.length);
        require(scoringExpertsManager.isExpertAssignedToProject(msg.sender, _projectId, _area));

        for (uint i = 0; i < _questionIds.length; i++) {
            var question = questionsMap[_questionIds[i]];
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

    function updateScoringsTokenAddress(uint _startIndex, uint _count, address _tokenAddress) external onlyOwner {
        require(_startIndex + _count <= scorings.length && _tokenAddress != 0);

        for (var i = _startIndex; i < _startIndex + _count; i++) {
            var scoring = Scoring(scorings[i]);
            scoring.setToken(_tokenAddress);
        }
    }

    function setToken(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != 0);
        token = SmartValleyToken(_tokenAddress);
    }

    function setMinter(address _minterAddress) public onlyOwner {
        require(_minterAddress != 0);
        minter = Minter(_minterAddress);
    }

    function setScoringExpertsManager(address _scoringExpertsManagerAddress) public onlyOwner {
        require(_scoringExpertsManagerAddress != 0);
        scoringExpertsManager = ScoringExpertsManager(_scoringExpertsManagerAddress);
    }

    function setScoringCost(uint _scoringCost) public onlyOwner {
        scoringCostWEI = _scoringCost * (10 ** uint(token.decimals()));
    }

    function setEstimateReward(uint _estimateReward) public onlyOwner {
        estimateRewardWEI = _estimateReward * (10 ** uint(token.decimals()));
    }
}
