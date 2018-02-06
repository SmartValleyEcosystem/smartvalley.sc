var EtherManager = artifacts.require("./EtherManager.sol");
var SmartValleyToken = artifacts.require("./SmartValleyToken.sol");
var BalanceFreezerMock = artifacts.require("./mock/BalanceFreezerMock.sol");
var Minter = artifacts.require("./Minter.sol");
var VotingManagerMock = artifacts.require("./mock/VotingManagerMock.sol");
var ScoringManager = artifacts.require("./ScoringManager.sol");
var AdministratorsRegistry = artifacts.require("./AdministratorsRegistry.sol");
var ExpertsRegistry = artifacts.require("./ExpertsRegistry.sol");

module.exports = function(deployer) {
  let token;
  let balanceFreeser;
  let minter;
  let scoringManager;
  let votingManager;

  deployer.deploy(EtherManager)
  .then(function() {
    return deployer.deploy(AdministratorsRegistry);
  })
  .then(function() {
    return AdministratorsRegistry.deployed();
  })
  .then(function(administratorsRegistryInstance) {
    let areas = [1, 2, 3, 4];
    return deployer.deploy(ExpertsRegistry, administratorsRegistryInstance.address, areas);
  })
  .then(function() {
    return deployer.deploy(BalanceFreezerMock);
  })
  .then(function() {
    return BalanceFreezerMock.deployed();
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
    return deployer.deploy(VotingManagerMock, balanceFreeser.address, token.address, 2);    
  })
  .then(function() {
    return VotingManagerMock.deployed();
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
