var SmartValleyTokenMock = artifacts.require("./mock/SmartValleyTokenMock.sol");
var BalanceFreezerMock = artifacts.require("./mock/BalanceFreezerMock.sol");
var MinterMock = artifacts.require("./mock/MinterMock.sol");
var VotingManagerMock = artifacts.require("./mock/VotingManagerMock.sol");
var ScoringManagerMock = artifacts.require("./mock/ScoringManagerMock.sol");

var SmartValleyToken = artifacts.require("./SmartValleyToken.sol");
var BalanceFreezer = artifacts.require("./BalanceFreezer.sol");
var Minter = artifacts.require("./Minter.sol");
var VotingManager = artifacts.require("./VotingManager.sol");
var ScoringManager = artifacts.require("./ScoringManager.sol");
var AdministratorsRegistry = artifacts.require("./AdministratorsRegistry.sol");
var ExpertsRegistry = artifacts.require("./ExpertsRegistry.sol");
var ScoringExpertsManager = artifacts.require("./ScoringExpertsManager.sol");
var RandomGenerator = artifacts.require("./RandomGenerator.sol");

module.exports = function(deployer) {

  var questions =      [1,  2, 3,   4,  5,  6, 7,  8,  9, 10, 11, 12, 13];
  var minScores =      [0,  0, 0, -15,  0,  0, 0,  0,  0,  0,  0,  0,  0];
  var maxScores =      [6, 10, 3,   0, 10, 15, 8, 10, 10,  7,  6,  5, 10];

  let areas = [1, 2, 3, 4];

  let freezer;
  let token;
  let voting;
  let minter;
  let scoring;
  let scoringExpertsManager;
  let expertsRegistry;
  let administratorsRegistry;

  if(deployer.network.includes('mock_')) {
    AdministratorsRegistry.new()
    .then(administratorsRegistryInstance => {
      administratorsRegistry = administratorsRegistryInstance;
      return ExpertsRegistry.new(administratorsRegistryInstance.address, areas);
    })
    .then(expertsRegistryInstance => {
      expertsRegistry = expertsRegistryInstance;
      return RandomGenerator.new();
    })
    .then(() => {
      deployer.link(RandomGenerator, ScoringExpertsManager);
      return ScoringExpertsManager.new(3, 2, expertsRegistry.address, administratorsRegistry.address);
    })
    .then(scoringExpertsManagerInstance => {
      scoringExpertsManager = scoringExpertsManagerInstance;
      return BalanceFreezerMock.new({overwrite: false});
    })
    .then((freezerInstance) => {
      freezer = freezerInstance
      return SmartValleyTokenMock.new(freezer.address, [], 1000 * (10 ** 18), {overwrite: false})
    })
    .then((tokenInstance) => {
      token = tokenInstance
      return VotingManagerMock.new(freezer.address, token.address, 2, {overwrite: false})
    })
    .then((votingInstance) => {
      voting = votingInstance
      voting.setAcceptanceThresholdPercent(50)
      return MinterMock.new(token.address, {overwrite: false})
    })
    .then((minterInstance) => {
      minter = minterInstance
      token.setMinter(minter.address)
      return ScoringManagerMock.new(token.address, 120, 10, minter.address, scoringExpertsManager.address, {overwrite: false})
    })
    .then((scoringInstance) => {
      scoring = scoringInstance
      minter.setScoringManagerAddress(scoring.address);
      scoring.setQuestions(questions, minScores, maxScores);
      token.addKnownContract(scoring.address);
      scoringExpertsManager.setScoringManager(scoring.address);
    });
  } else {
    AdministratorsRegistry.new()
    .then(administratorsRegistryInstance => {
      administratorsRegistry = administratorsRegistryInstance;
      return ExpertsRegistry.new(administratorsRegistryInstance.address, areas);
    })
    .then(expertsRegistryInstance => {
      expertsRegistry = expertsRegistryInstance;
      return deployer.deploy(RandomGenerator);
    })
    .then(() => {
      return RandomGenerator.deployed();
    })
    .then(() => {
      deployer.link(RandomGenerator, ScoringExpertsManager);
      return ScoringExpertsManager.new(3, 2, expertsRegistry.address, administratorsRegistry.address);
    })
    .then(scoringExpertsManagerInstance => {
      scoringExpertsManager = scoringExpertsManagerInstance;
      return BalanceFreezer.new();
    })
    .then((freezerInstance) => {
      freezer = freezerInstance;
      return SmartValleyToken.new(freezer.address);
    })
    .then((tokenInstance) => {
      token = tokenInstance;
      return VotingManager.new(freezer.address, token.address, 2);
    })
    .then((votingInstance) => {
      voting = votingInstance;
      voting.setAcceptanceThresholdPercent(50);
      return Minter.new(token.address);
    })
    .then((minterInstance) => {
      minter = minterInstance;
      token.setMinter(minter.address);
      return ScoringManager.new(token.address, 120, 10, minter.address, scoringExpertsManager.address);
    })
    .then((scoringInstance) => {
      scoring = scoringInstance;
      minter.setScoringManagerAddress(scoring.address);
      scoring.setQuestions(questions, minScores, maxScores);
      token.addKnownContract(scoring.address);
      scoringExpertsManager.setScoringManager(scoring.address);
    });
  }
}