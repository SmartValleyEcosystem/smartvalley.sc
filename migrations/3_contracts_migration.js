var VotingManagerMock = artifacts.require("./mock/VotingManagerMock.sol");
var ScoringManagerMock = artifacts.require("./mock/ScoringManagerMock.sol");

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
  let areaEstimateRewards = [1, 1, 1, 1];
  
  let voting; 
  let scoring;
  let scoringExpertsManager;
  let expertsRegistry;
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
      return deployer.deploy(RandomGenerator);
    })
    .then(() => {
      return RandomGenerator.deployed();
    })
    .then(() => {
      deployer.link(RandomGenerator, ScoringExpertsManager);
      return deployer.deploy(ScoringExpertsManager, 3, 2, expertsRegistry.address, administratorsRegistry.address);
    })
    .then(() => {
      return ScoringExpertsManager.deployed();
    })
    .then(scoringExpertsManagerInstance => {
      scoringExpertsManager = scoringExpertsManagerInstance;    
      return deployer.deploy(ScoringManagerMock, scoringExpertsManager.address, areas, getRewards(), {overwrite: false})
    })
    .then(() => {
      return ScoringManagerMock.deployed();
    })
    .then((scoringInstance) => {
      scoring = scoringInstance;      
      scoring.setQuestions(questions, minScores, maxScores);      
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
      return deployer.deploy(RandomGenerator);
    })
    .then(() => {
      return RandomGenerator.deployed();
    })
    .then(() => {
      deployer.link(RandomGenerator, ScoringExpertsManager);
      return deployer.deploy(ScoringExpertsManager, 3, 2, expertsRegistry.address, administratorsRegistry.address);
    })
    .then(() => {
      return ScoringExpertsManager.deployed();
    })
    .then(scoringExpertsManagerInstance => {
      scoringExpertsManager = scoringExpertsManagerInstance;   
      return deployer.deploy(ScoringManager, scoringExpertsManager.address, areas, getRewards());
    })
    .then(() => {
      return ScoringManager.deployed();
    })
    .then((scoringInstance) => {
      scoring = scoringInstance;      
      scoring.setQuestions(questions, minScores, maxScores);      
      scoringExpertsManager.setScoringManager(scoring.address);
    });
  }
}