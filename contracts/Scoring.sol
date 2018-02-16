pragma solidity ^ 0.4.19;

import "./Owned.sol";
import "./SmartValleyToken.sol";
import "./ScoringExpertsManager.sol";

contract Scoring is Owned {
    struct Estimate {
        uint questionId;
        address expertAddress;
        int score;
        bytes32 commentHash;
    }

    struct AreaScoring {
        uint expertsCount;
        int sum;
        uint submissionsCount;
        mapping(address => bool) experts;
    }

    SmartValleyToken public token;

    address public author;
    int public score;
    Estimate[] public estimates;
    mapping(uint => AreaScoring) public areaScorings;
    uint[] public areas;
    uint public scoredAreasCount;

    function Scoring(address _author, address _tokenAddress, uint[] _areas, uint[] _areaExpertCounts) public {
        author = _author;
        areas = _areas;
        for (uint i = 0; i < _areas.length; i++) {
            areaScorings[areas[i]].expertsCount = _areaExpertCounts[i];
        }
        setToken(_tokenAddress);
    }

    function submitEstimates(address _expert, uint _area, uint[] _questionIds, int[] _scores, bytes32[] _commentHashes, uint _estimateRewardWEI) external onlyOwner {
        require(_questionIds.length == _scores.length && _scores.length == _commentHashes.length);
        
        AreaScoring storage areaScoring = areaScorings[_area];
        require(!areaScoring.experts[_expert]);
        require(areaScoring.submissionsCount < areaScoring.expertsCount);

        areaScoring.experts[_expert] = true;
        areaScoring.submissionsCount++;

        if (areaScoring.submissionsCount == areaScoring.expertsCount)
            scoredAreasCount++;

        token.transfer(_expert, _estimateRewardWEI);

        for (uint i = 0; i < _questionIds.length; i++) {
            estimates.push(Estimate(_questionIds[i], _expert, _scores[i], _commentHashes[i]));
            areaScoring.sum += _scores[i];
        }

        if (scoredAreasCount != areas.length)
            return;

        score = calculateScore();
    }

    function getEstimates() external view returns(uint[] _questions, int[] _scores, address[] _experts) {
        uint[] memory questions = new uint[](estimates.length);
        int[] memory scores = new int[](estimates.length);
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

    function getResults() external view returns(bool _isScored, int _score, uint[] _areas, bool[] _areaResults) {
        _isScored = scoredAreasCount == areas.length;
        _score = score;
        _areas = areas;
        _areaResults = new bool[](areas.length);
        for (uint i = 0; i < _areas.length; i++) {
            AreaScoring storage areaScoring = areaScorings[_areas[i]];
            _areaResults[i] = areaScoring.submissionsCount == areaScoring.expertsCount;
        }
    }

    function setToken(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != 0);
        token = SmartValleyToken(_tokenAddress);
    }

    function calculateScore() private view returns(int) {
        int sum = 0;
        for (uint i = 0; i < areas.length; i++) {
            AreaScoring storage areaScoring = areaScorings[areas[i]];
            sum += areaScoring.sum / int(areaScoring.expertsCount);
        }
        return sum;
    }
}