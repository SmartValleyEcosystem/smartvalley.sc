var Scoring = artifacts.require("./Scoring.sol");
var Project = artifacts.require("./Project.sol");
var SmartValleyToken = artifacts.require("./SmartValleyToken.sol");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(Scoring)
  .then(function() {
    return Scoring.deployed();
  })
  .then(function (scoringInstance) {
    var questions =      [1,  2, 3,   4,  5,  6, 7,  8,  9, 10, 11, 12, 13];
    var expertiseAreas = [1,  1, 1,   1,  4,  4, 2,  2,  2,  3,  3,  3,  3];
    var minScores =      [0,  0, 0, -15,  0,  0, 0,  0,  0,  0,  0,  0,  0];
    var maxScores =      [6, 10, 3,   0, 10, 15, 8, 10, 10,  7,  6,  5, 10];

    return scoringInstance.addQuestions(expertiseAreas, questions, minScores, maxScores);
  });
};
