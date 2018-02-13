pragma solidity ^ 0.4.19;

import "./Owned.sol";
import "./SmartValleyToken.sol";

contract Scoring is Owned {
    struct Estimate {
        uint area;
        uint questionId;
        address expertAddress;
        int score;
        bytes32 commentHash;
    }

    SmartValleyToken public token;

    address public author;
    bool public isScored;
    int public score;
    Estimate[] public estimates;
    mapping(uint => uint) public areaSubmissionsCounters;
    mapping(uint => mapping(address => bool)) public expertEstimatesByArea;
    uint public expectedSubmissionsCount;
    uint public currentSubmissionsCount;
    uint public estimateRewardWEI;
    uint[] public areas;
    mapping(uint => uint) areaExpertCounts;
    mapping(uint => int) areaSums;

    function Scoring(address _author, address _tokenAddress, uint _estimateRewardWEI, uint[] _areas, uint[] _areaExpertCounts) public {
        author = _author;
        areas = _areas;
        for (uint i = 0; i < _areas.length; i++) {
            areaExpertCounts[areas[i]] = _areaExpertCounts[i];
            expectedSubmissionsCount += _areaExpertCounts[i];
        }
        setToken(_tokenAddress);
        estimateRewardWEI = _estimateRewardWEI;
    }

    function submitEstimates(address _expert, uint _area, uint[] _questionIds, int[] _scores, bytes32[] _commentHashes) external onlyOwner {
        require(!isScored);
        require(!expertEstimatesByArea[_area][_expert]);
        require(areaSubmissionsCounters[_area] < areaExpertCounts[_area]);

        require(_questionIds.length == _scores.length && _scores.length == _commentHashes.length);

        expertEstimatesByArea[_area][_expert] = true;
        areaSubmissionsCounters[_area]++;
        currentSubmissionsCount++;

        token.transfer(_expert, estimateRewardWEI);

        for (uint i = 0; i < _questionIds.length; i++) {
            estimates.push(Estimate(_area, _questionIds[i], _expert, _scores[i], _commentHashes[i]));
            areaSums[_area] += _scores[i];
        }

        if (currentSubmissionsCount != expectedSubmissionsCount)
            return;

        score = calculateScore();
        isScored = true;
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

    function getResults() external view returns(bool _isScored, int _score, uint[] _areas, bool[] _areaResults) {
        _isScored = isScored;
        _score = score;
        _areas = areas;
        _areaResults = new bool[](areas.length);
        for (uint i = 0; i < _areas.length; i++) {
            var area = _areas[i];
            _areaResults[i] = areaSubmissionsCounters[area] == areaExpertCounts[area];
        }
    }

    function setToken(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != 0);
        token = SmartValleyToken(_tokenAddress);
    }

    function calculateScore() private view returns(int) {
        int sum = 0;
        for (uint i = 0; i < areas.length; i++) {
            var area = areas[i];
            sum += areaSums[area] / int(areaExpertCounts[area]);
        }
        return sum;
    }
}