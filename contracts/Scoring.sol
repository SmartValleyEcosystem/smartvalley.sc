pragma solidity ^ 0.4.18;

import "./Owned.sol";
import "./Project.sol";

contract Scoring is Owned {
    struct Question {
        int minScore;
        int maxScore;
    }

    mapping(uint => mapping(uint => Question)) public questionsByArea;
    mapping(address => mapping(uint => mapping(address => bool))) public scoredProjectsByArea;

    function submitEstimates(address _projectAddress, uint _expertiseArea, uint[] _questionIds, int[] _scores, bytes32[] _commentHashes) external {
        require(_questionIds.length == _scores.length && _scores.length == _commentHashes.length);

        for (uint i = 0; i < _questionIds.length; i++) {
            var question = questionsByArea[_expertiseArea][_questionIds[i]];
            require(question.minScore != question.maxScore);
            require(_scores[i] <= question.maxScore && _scores[i] >= question.minScore);
        }

        require(!scoredProjectsByArea[msg.sender][_expertiseArea][_projectAddress]);

        scoredProjectsByArea[msg.sender][_expertiseArea][_projectAddress] = true;

        Project project = Project(_projectAddress);
        project.submitEstimates(msg.sender, _expertiseArea, _questionIds, _scores, _commentHashes);
    }

    function addQuestions(uint[] _expertiseAreas, uint[] _questionIds, int[] _minScores, int[] _maxScores) external onlyOwner {
        require(_expertiseAreas.length == _questionIds.length && _questionIds.length == _minScores.length && _minScores.length == _maxScores.length);

        for (uint i = 0; i < _questionIds.length; i++) {
            questionsByArea[_expertiseAreas[i]][_questionIds[i]] = Question(_minScores[i], _maxScores[i]);
        }
    }
}
