pragma solidity ^ 0.4.18;

import "./Owned.sol";
import "./ScoringExpertsManager.sol";

contract Scoring is Owned {
    struct Estimate {
        uint questionId;
        address expertAddress;
        uint score;
        bytes32 commentHash;
    }

    struct AreaScoring {
        uint estimateRewardWEI;
        uint expertsCount;
        uint maxScore;
        uint maxSum;
        uint sum;
        uint submissionsCount;
        mapping(address => bool) experts;
    }

    uint public SCORE_PRECISION = 2;

    address public author;
    uint public score;
    Estimate[] public estimates;
    mapping(uint => AreaScoring) public areaScorings;
    uint[] public areas;
    uint public scoredAreasCount;
    mapping(uint => mapping(address => bytes32)) conclusionHashes;

    function Scoring(address _author, uint[] _areas, uint[] _areaExpertCounts, uint[] _areaEstimateRewardsWEI, uint[] _areaMaxScores) public {
        author = _author;
        areas = _areas;
        for (uint i = 0; i < _areas.length; i++) {
            areaScorings[areas[i]].expertsCount = _areaExpertCounts[i];
            areaScorings[areas[i]].estimateRewardWEI = _areaEstimateRewardsWEI[i];
            areaScorings[areas[i]].maxScore = _areaMaxScores[i];
        }
    }

    function() public payable {}

    function submitEstimates(address _expert, uint _area, bytes32 _conclusionHash, uint[] _questionIds, uint[] _questionWeights, uint[] _scores, bytes32[] _commentHashes) external onlyOwner {
        require(_questionIds.length == _scores.length && _scores.length == _commentHashes.length);

        AreaScoring storage areaScoring = areaScorings[_area];
        require(!areaScoring.experts[_expert] && areaScoring.submissionsCount < areaScoring.expertsCount);

        areaScoring.experts[_expert] = true;
        areaScoring.submissionsCount++;

        conclusionHashes[_area][_expert] = _conclusionHash;

        if (areaScoring.submissionsCount == areaScoring.expertsCount)
            scoredAreasCount++;

        for (uint i = 0; i < _questionIds.length; i++) {
            addEstimate(_questionIds[i], _expert, _scores[i], _commentHashes[i]);

            areaScoring.sum += _scores[i] * _questionWeights[i];
            areaScoring.maxSum += 2 * _questionWeights[i];
        }

        _expert.transfer(areaScoring.estimateRewardWEI);

        if (scoredAreasCount != areas.length)
            return;

        score = calculateScore();
    }

    function getEstimates() external view returns(uint[] _questions, uint[] _scores, address[] _experts) {
        uint[] memory questions = new uint[](estimates.length);
        uint[] memory scores = new uint[](estimates.length);
        address[] memory experts = new address[](estimates.length);

        for (uint i = 0; i < estimates.length; i++) {
            Estimate memory estimate = estimates[i];

            questions[i] = estimate.questionId;
            scores[i] = estimate.score;
            experts[i] = estimate.expertAddress;
        }

        _questions = questions;
        _scores = scores;
        _experts = experts;
    }

    function getRequiredSubmissionsInArea(uint _area) external view returns(uint) {
        return areaScorings[_area].expertsCount;
    }

    function getResults() external view returns(bool _isScored, uint _score, uint[] _areas, bool[] _areaResults, uint[] _areaScores) {
        _isScored = scoredAreasCount == areas.length;
        _score = score;
        _areas = areas;
        _areaResults = new bool[](areas.length);
        _areaScores = new uint[](areas.length);
        
        for (uint i = 0; i < _areas.length; i++) {
            AreaScoring storage areaScoring = areaScorings[_areas[i]];
            bool isCompleted = areaScoring.submissionsCount == areaScoring.expertsCount;
            _areaResults[i] = isCompleted;
            if (isCompleted) {
                _areaScores[i] = getAreaScore(_areas[i]);
            }
        }
    }

    function getScoringCost() external view returns(uint _scoringCost) {
        _scoringCost = 0;

        for (uint i = 0; i < areas.length; i++) {
          uint expertsCount = areaScorings[areas[i]].expertsCount;
          uint areaEstimateRewardsWEI = areaScorings[areas[i]].estimateRewardWEI;

          _scoringCost += areaEstimateRewardsWEI * expertsCount;
        }
    }

    function getAreaScore(uint _area) private view returns(uint) {
        AreaScoring storage areaScoring = areaScorings[_area];
        return (areaScoring.sum * (10 ** SCORE_PRECISION) / areaScoring.maxSum) * areaScoring.maxScore;
    }

    function addEstimate(uint _questionId, address _expertAddress, uint _score, bytes32 _commentHash) private {
        estimates.push(Estimate(_questionId, _expertAddress, _score, _commentHash));
    }

    function calculateScore() private view returns(uint) {
        uint sum = 0;
        for (uint i = 0; i < areas.length; i++) {
            sum += getAreaScore(areas[i]);
        }
        return sum;
    }
}