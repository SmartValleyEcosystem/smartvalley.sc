pragma solidity ^ 0.4.24;

import "./Owned.sol";
import "./ScoringParametersProvider.sol";

contract Scoring is Owned {

    struct Estimate {
        uint criterionId;
        address expertAddress;
        uint score;
        bytes32 commentHash;
    }

    uint public SCORE_PRECISION = 2;

    ScoringParametersProvider public scoringParametersProvider;

    mapping(uint => Estimate[]) public estimates;
    mapping(uint => mapping(address => bytes32)) conclusionHashes;

    constructor(address _scoringParametersProviderAddress) public {
        scoringParametersProvider = ScoringParametersProvider(_scoringParametersProviderAddress);
    }

    function() external payable {}

    function submitEstimates(
        address _expert,
        uint _area,
        bytes32 _conclusionHash,
        uint[] _criterionIds,
        uint[] _scores,
        bytes32[] _commentHashes) external onlyOwner {

        require(_criterionIds.length == _scores.length && _scores.length == _commentHashes.length);

        conclusionHashes[_area][_expert] = _conclusionHash;

        for (uint i = 0; i < _criterionIds.length; i++) {
            require(scoringParametersProvider.getCriterionArea(_criterionIds[i]) == _area);

            estimates[_area].push(Estimate(_criterionIds[i], _expert, _scores[i], _commentHashes[i]));
        }

        uint reward = getReward(_area);
        _expert.transfer(reward);
    }

    function getReward(uint _area) private view returns(uint) {
        return scoringParametersProvider.getAreaReward(_area);
    }

    function getEstimates() external view returns(uint[] _criteria, uint[] _scores, address[] _experts) {
        uint totalCount = getEstimatesCount();

        _criteria = new uint[](totalCount);
        _scores = new uint[](totalCount);
        _experts = new address[](totalCount);

        uint[] memory areas = getAreas();
        uint resultIndex = 0;
        for (uint i = 0; i < areas.length; i++) {
            for (uint j = 0; j < estimates[areas[i]].length; j++) {
                Estimate memory estimate = estimates[areas[i]][j];

                _criteria[resultIndex] = estimate.criterionId;
                _scores[resultIndex] = estimate.score;
                _experts[resultIndex] = estimate.expertAddress;

                resultIndex++;
            }
        }
    }

    function getResults() external view returns(uint _score, uint[] _areas, uint[] _areaScores) {
        _areas = getAreas();
        _areaScores = new uint[](_areas.length);

        for (uint i = 0; i < _areas.length; i++) {
            uint areaScore = getAreaScore(_areas[i]);

            _areaScores[i] = areaScore;
            _score += areaScore;
        }
    }

    function getConclusionHash(uint _area, address _expert) external view returns(bytes32) {
        return conclusionHashes[_area][_expert];
    }

    function getAreas() public view returns(uint[]) {
        return scoringParametersProvider.getAreas();
    }

    function getAreaScore(uint _area) private view returns(uint) {
        if(estimates[_area].length == 0) {
            return 0;
        }

        uint sum = 0;
        uint maxSum = 0;

        for (uint i = 0; i < estimates[_area].length; i++) {
            Estimate storage estimate = estimates[_area][i];
            uint criterionWeight = scoringParametersProvider.getCriterionWeight(estimate.criterionId);
            sum += estimate.score * criterionWeight;
            maxSum += 2 * criterionWeight;
        }

        uint maxScore = scoringParametersProvider.getAreaMaxScore(_area);
        return (sum * (10 ** SCORE_PRECISION) / maxSum) * maxScore;
    }

    function getEstimatesCount() private view returns(uint) {
        uint[] memory areas = getAreas();
        uint result = 0;
        for (uint i = 0; i < areas.length; i++) {
            result += estimates[areas[i]].length;
        }
        return result;
    }
}