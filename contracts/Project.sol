pragma solidity ^ 0.4.18;

import "./Owned.sol";

contract Project is Owned {
    struct Estimate {
        uint questionId;
        address expertAddress;
        uint score;
        bytes32 commentHash;
    }

    uint public constant REQUIRED_SUBMISSIONS_COUNT = 3 * 4;

    address public author;
    string public name;
    bool public isScored;
    uint public score;
    Estimate[] public estimates;
    mapping(uint => uint) public areaSubmissionsCounters;
    mapping(uint => mapping(address => bool)) public expertsByArea;
    uint public submissionsCount;

    function Project(address _author, string _name) public {
        author = _author;
        name = _name;
    }

    function submitEstimates(uint _expertiseArea, uint[] _questionIds, uint[] _scores, bytes32[] _commentHashes) public {
        require(!isScored);
        require(!expertsByArea[_expertiseArea][msg.sender]);
        require(areaSubmissionsCounters[_expertiseArea] < 3);
        require(_questionIds.length == _scores.length && _scores.length == _commentHashes.length);

        expertsByArea[_expertiseArea][msg.sender] = true;
        areaSubmissionsCounters[_expertiseArea]++;
        submissionsCount++;

        for (uint i = 0; i < _questionIds.length; i++) {
            estimates.push(Estimate(_questionIds[i], msg.sender, _scores[i], _commentHashes[i]));
        }

        if (submissionsCount != REQUIRED_SUBMISSIONS_COUNT)
            return;

        score = calculateScore();
        isScored = true;
    }

    function getEstimatesCount() public view returns(uint) {
        return estimates.length;
    }

    function getEstimates() public view returns(uint[], uint[]) {
        uint[] memory questions = new uint[](estimates.length);
        uint[] memory scores = new uint[](estimates.length);

        for (uint i = 0; i < estimates.length; i++) {
            questions[i] = estimates[i].questionId;
            scores[i] = estimates[i].score;
        }

        return (questions, scores);
    }

    function calculateScore() internal view returns(uint) {
        uint sum = 0;
        for (uint i = 0; i < estimates.length; i++) {
            sum += estimates[i].score;
        }
        return sum / 3;
    }
}