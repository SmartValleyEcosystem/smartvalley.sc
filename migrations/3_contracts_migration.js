var VotingManagerMock = artifacts.require("./mock/VotingManagerMock.sol");
var ScoringManagerMock = artifacts.require("./mock/ScoringManagerMock.sol");

var VotingManager = artifacts.require("./VotingManager.sol");
var ScoringManager = artifacts.require("./ScoringManager.sol");
var AdministratorsRegistry = artifacts.require("./AdministratorsRegistry.sol");
var ExpertsRegistry = artifacts.require("./ExpertsRegistry.sol");
var ScoringsRegistry = artifacts.require("./ScoringsRegistry.sol");
var ScoringExpertsManager = artifacts.require("./ScoringExpertsManager.sol");
var RandomGenerator = artifacts.require("./RandomGenerator.sol");

module.exports = function(deployer) {
  //                    ----------------- LAWYER ------------------     ------------------- HR -------------------     ---- TECH ----     ---------------------------------- ANALYST -----------------------------------     ----------------------------------- MARKETER ---------------------------------
  var questions =       [1,  2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13,    14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,    25, 26, 27, 28,    29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48,    49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68];
  var questionWeights = [10, 3, 1, 4, 4, 2, 8, 4, 8,  4,  7,  3,  3,    10, 10,  3,  4,  7,  3,  6,  5,  5,  2,  3,     5,  3, 10,  5,    10, 10,  7,  5,  6,  2,  5,  2,  2,  5,  3, 10, 10,  7,  5,  3,  8,  5,  3,  5,     3,  7,  9,  9, 10,  6, 10,  9,  6,  4,  4,  4,  4,  6,  4,  6,  8,  3,  5,  7];

  let areas =               [ 1,  2,  3,  4,  5];
  let areaMaxScores =       [16, 23, 17, 27, 17];
  let areaEstimateRewards = [ 1,  1,  1,  1,  1];

  let voting; 
  let scoring;
  let scoringExpertsManager;
  let expertsRegistry;
  let scoringsRegistry;
  let administratorsRegistry;

  function getRewards() {
    rewardsWei = [];
    for (i = 0; i < areas.length; i++) {
        rewardsWei.push(web3.toWei(areaEstimateRewards[i]))
    }  
    return rewardsWei;
  }

  if(deployer.network.includes('mock_')) {
    deployer.deploy(AdministratorsRegistry)
    .then(() => {
      return AdministratorsRegistry.deployed();
    })
    .then(administratorsRegistryInstance => {
      administratorsRegistry = administratorsRegistryInstance;
      return deployer.deploy(ExpertsRegistry, administratorsRegistryInstance.address, areas);
    })
    .then(() => {
      return ExpertsRegistry.deployed();
    })
    .then(expertsRegistryInstance => {
      expertsRegistry = expertsRegistryInstance;
      return deployer.deploy(ScoringsRegistry);
    })
    .then(() => {
      return ScoringsRegistry.deployed();
    })
    .then(scoringsRegistryInstance => {
      scoringsRegistry = scoringsRegistryInstance;
      return deployer.deploy(RandomGenerator);
    })
    .then(() => {
      return RandomGenerator.deployed();
    })
    .then(() => {
      deployer.link(RandomGenerator, ScoringExpertsManager);
      return deployer.deploy(ScoringExpertsManager, 3, 2, 2, expertsRegistry.address, administratorsRegistry.address, scoringsRegistry.address);
    })
    .then(() => {
      return ScoringExpertsManager.deployed();
    })
    .then(scoringExpertsManagerInstance => {
      scoringExpertsManager = scoringExpertsManagerInstance;
      return deployer.deploy(ScoringManagerMock, scoringExpertsManager.address, administratorsRegistry.address, scoringsRegistry.address, areas, getRewards(), areaMaxScores, {overwrite: false})
    })
    .then(() => {
      return ScoringManagerMock.deployed();
    })
    .then((scoringInstance) => {
      scoring = scoringInstance;
      scoring.setQuestions(questions, questionWeights);
      scoringExpertsManager.setScoringManager(scoring.address);
    });
  } else {
    deployer.deploy(AdministratorsRegistry)
    .then(() => {
      return AdministratorsRegistry.deployed();
    })
    .then(administratorsRegistryInstance => {
      administratorsRegistry = administratorsRegistryInstance;
      return deployer.deploy(ExpertsRegistry, administratorsRegistryInstance.address, areas);
    })
    .then(() => {
      return ExpertsRegistry.deployed();
    })
    .then(expertsRegistryInstance => {
      expertsRegistry = expertsRegistryInstance;
      return deployer.deploy(ScoringsRegistry);
    })
    .then(() => {
      return ScoringsRegistry.deployed();
    })
    .then(scoringsRegistryInstance => {
      scoringsRegistry = scoringsRegistryInstance;
      return deployer.deploy(RandomGenerator);
    })
    .then(() => {
      return RandomGenerator.deployed();
    })
    .then(() => {
      deployer.link(RandomGenerator, ScoringExpertsManager);
      return deployer.deploy(ScoringExpertsManager, 3, 2, 2, expertsRegistry.address, administratorsRegistry.address, scoringsRegistry.address);
    })
    .then(() => {
      return ScoringExpertsManager.deployed();
    })
    .then(scoringExpertsManagerInstance => {
      scoringExpertsManager = scoringExpertsManagerInstance;
      return deployer.deploy(ScoringManager, scoringExpertsManager.address, administratorsRegistry.address, scoringsRegistry.address, areas, getRewards(), areaMaxScores);
    })
    .then(() => {
      return ScoringManager.deployed();
    })
    .then((scoringInstance) => {
      scoring = scoringInstance;
      scoring.setQuestions(questions, questionWeights);
      scoringExpertsManager.setScoringManager(scoring.address);
    });
  }
}