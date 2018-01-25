var EtherManager = artifacts.require("./EtherManager.sol");
var SmartValleyToken = artifacts.require("./SmartValleyToken.sol");
var BalanceFreezer = artifacts.require("./BalanceFreezer.sol");
var Minter = artifacts.require("./Minter.sol");
var VotingManager = artifacts.require("./VotingManager.sol");
var ScoringManager = artifacts.require("./ScoringManager.sol");

module.exports = function(deployer) {
  let token;
  let balanceFreeser;
  let minter;
  let scoringManager;
  let votingManager;

  deployer.deploy(EtherManager)
  .then(function() {
    return deployer.deploy(BalanceFreezer);
  })
  .then(function() {
    return BalanceFreezer.deployed();
  })
  .then(function(balanceFreezerInstance) {
    balanceFreeser = balanceFreezerInstance;
    return deployer.deploy(SmartValleyToken, balanceFreeser.address);
  })
  .then(function() {
    return SmartValleyToken.deployed();
  })
  .then(function(tokenInstance) {
    token = tokenInstance;
    return deployer.deploy(VotingManager, balanceFreeser.address, token.address, 2);
  })
  .then(function() {
    return VotingManager.deployed();
  })
  .then(function(votingManagerInstance) {
    votingManager = votingManagerInstance;
    return votingManager.setAcceptanceThresholdPercent(50);    
  })
  .then(function() {
    return deployer.deploy(Minter, token.address);
  })
  .then(function() {
    return Minter.deployed();
  })
  .then(function(minterInstance) {
    minter = minterInstance;
    return token.setMinter(minter.address);
  })
  .then(function() {
    return deployer.deploy(ScoringManager, token.address, 120, 10, minter.address);
  })
  .then(function() {
    return ScoringManager.deployed();
  })
  .then(function(scoringManagerInstance) {
    scoringManager = scoringManagerInstance;
    return minter.setScoringManagerAddress(scoringManagerInstance.address);
  })
  .then(function() {
    var questions =      [1,  2, 3,   4,  5,  6, 7,  8,  9, 10, 11, 12, 13];
    var expertiseAreas = [1,  1, 1,   1,  4,  4, 2,  2,  2,  3,  3,  3,  3];
    var minScores =      [0,  0, 0, -15,  0,  0, 0,  0,  0,  0,  0,  0,  0];
    var maxScores =      [6, 10, 3,   0, 10, 15, 8, 10, 10,  7,  6,  5, 10];
    return scoringManager.setQuestions(expertiseAreas, questions, minScores, maxScores);
  })
  .then(function() {
    return token.addKnownContract(scoringManager.address);
  });
};
