pragma solidity ^ 0.4.23;

import "./Owned.sol";

contract Scoring is Owned {
    struct Estimate {
        uint questionId;
        address expertAddress;
        uint score;
        bytes32 commentHash;
    }

    struct AreaScoring {
        uint estimateRewardWei;
        uint expectedSubmissionsCount;
        uint currentSubmissionsCount;
        uint maxScore;
        uint maxSum;
        uint sum;
        mapping(address => bytes32) conclusionHashes;
    }

    uint public SCORE_PRECISION = 2;

    address public author;
    Estimate[] public estimates;
    mapping(uint => AreaScoring) public areaScorings;
    uint[] public areas;

    constructor(address _author, uint[] _areas, uint[] _areaExpertCounts, uint[] _areaEstimateRewardsWei, uint[] _areaMaxScores) public {
        author = _author;
        areas = _areas;
        for (uint i = 0; i < _areas.length; i++) {
            areaScorings[areas[i]].expectedSubmissionsCount = _areaExpertCounts[i];
            areaScorings[areas[i]].estimateRewardWei = _areaEstimateRewardsWei[i];
            areaScorings[areas[i]].maxScore = _areaMaxScores[i];
        }
    }

    function() public payable {}

    function submitEstimates(
        address _expert,
        uint _area,
        bytes32 _conclusionHash,
        uint[] _questionIds,
        uint[] _questionWeights,
        uint[] _scores,
        bytes32[] _commentHashes) external onlyOwner {

        require(_questionIds.length == _scores.length && _scores.length == _commentHashes.length);

        AreaScoring storage areaScoring = areaScorings[_area];
        require(areaScoring.currentSubmissionsCount < areaScoring.expectedSubmissionsCount);

        areaScoring.currentSubmissionsCount++;
        areaScoring.conclusionHashes[_expert] = _conclusionHash;

        for (uint i = 0; i < _questionIds.length; i++) {
            estimates.push(Estimate(_questionIds[i], _expert, _scores[i], _commentHashes[i]));

            areaScoring.sum += _scores[i] * _questionWeights[i];
            areaScoring.maxSum += 2 * _questionWeights[i];
        }

        _expert.transfer(areaScoring.estimateRewardWei);
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

    function getResults() external view returns(bool _isScored, uint _score, uint[] _areas, bool[] _areaCompleteness, uint[] _areaScores) {
        _isScored = true;
        _areas = areas;
        _areaCompleteness = new bool[](areas.length);
        _areaScores = new uint[](areas.length);

        uint score = 0;
        for (uint i = 0; i < _areas.length; i++) {
            AreaScoring storage areaScoring = areaScorings[_areas[i]];
            bool isAreaCompleted = areaScoring.currentSubmissionsCount == areaScoring.expectedSubmissionsCount;
            _areaCompleteness[i] = isAreaCompleted;
            if (isAreaCompleted) {
                uint areaScore = getAreaScore(_areas[i]);
                _areaScores[i] = areaScore;
                score += areaScore;
            } else {
                _isScored = false;
            }
        }

        if(_isScored) {
            _score = score;
        }
    }

    function getScoringCost() external view returns(uint _scoringCost) {
        _scoringCost = 0;

        for (uint i = 0; i < areas.length; i++) {
            uint expertsCount = areaScorings[areas[i]].expectedSubmissionsCount;
            uint areaEstimateRewardWei = areaScorings[areas[i]].estimateRewardWei;

            _scoringCost += areaEstimateRewardWei * expertsCount;
        }
    }

    function getConclusionHash(uint _area, address _expert) external view returns(bytes32) {
        return areaScorings[_area].conclusionHashes[_expert];
    }

    function getAreaScore(uint _area) private view returns(uint) {
        AreaScoring storage areaScoring = areaScorings[_area];
        return (areaScoring.sum * (10 ** SCORE_PRECISION) / areaScoring.maxSum) * areaScoring.maxScore;
    }
}