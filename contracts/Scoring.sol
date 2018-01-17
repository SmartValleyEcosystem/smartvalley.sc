pragma solidity ^ 0.4.18;

import "./Owned.sol";
import "./SmartValleyToken.sol";

contract Scoring is Owned {
    struct Estimate {
        uint questionId;
        address expertAddress;
        int score;
        bytes32 commentHash;
    }

    uint public constant REQUIRED_SUBMISSIONS_IN_AREA = 3;
    uint public constant REQUIRED_SUBMISSIONS = REQUIRED_SUBMISSIONS_IN_AREA * 4;

    address public author;  
    bool public isScored;
    int public score;
    Estimate[] public estimates;
    mapping(uint => uint) public areaSubmissionsCounters;
    mapping(uint => mapping(address => bool)) public expertsByArea;
    uint public submissionsCount;
    SmartValleyToken public svt;
    uint public estimateRewardWEI;   

    function Scoring(address _author, address _svtAddress, uint _estimateRewardWEI) public {
        author = _author;        
        setTokenAddress(_svtAddress);      
        estimateRewardWEI = _estimateRewardWEI;
    }    

    function submitEstimates(address _expert, uint _expertiseArea, uint[] _questionIds, int[] _scores, bytes32[] _commentHashes) external onlyOwner {
        require(!isScored);
        require(!expertsByArea[_expertiseArea][_expert]);
        require(areaSubmissionsCounters[_expertiseArea] < REQUIRED_SUBMISSIONS_IN_AREA);

        require(_questionIds.length == _scores.length && _scores.length == _commentHashes.length);

        expertsByArea[_expertiseArea][_expert] = true;
        areaSubmissionsCounters[_expertiseArea]++;
        submissionsCount++;

        svt.transfer(_expert, estimateRewardWEI);

        for (uint i = 0; i < _questionIds.length; i++) {
            estimates.push(Estimate(_questionIds[i], _expert, _scores[i], _commentHashes[i]));
        }

        if (submissionsCount != REQUIRED_SUBMISSIONS)
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

    function getScoringInformation() external view returns(bool _isScored, int _score, bool _isScoredByHr, bool _isScoredByAnalyst, bool _isScoredByTech, bool _isScoredByLawyer) {
        _isScored = isScored;
        _score = score;

        _isScoredByHr = areaSubmissionsCounters[1] == REQUIRED_SUBMISSIONS_IN_AREA;
        _isScoredByAnalyst = areaSubmissionsCounters[2] == REQUIRED_SUBMISSIONS_IN_AREA;
        _isScoredByTech = areaSubmissionsCounters[3] == REQUIRED_SUBMISSIONS_IN_AREA;
        _isScoredByLawyer = areaSubmissionsCounters[4] == REQUIRED_SUBMISSIONS_IN_AREA;
    }

    function calculateScore() internal view returns(int) {
        int sum = 0;
        for (uint i = 0; i < estimates.length; i++) {
            sum += estimates[i].score;
        }
        return sum / int(REQUIRED_SUBMISSIONS_IN_AREA);
    }

    function setTokenAddress(address _svtAddress) public onlyOwner {
        require(_svtAddress != 0);
        svt = SmartValleyToken(_svtAddress);
    }
}