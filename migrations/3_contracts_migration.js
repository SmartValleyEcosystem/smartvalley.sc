var ScoringManager = artifacts.require("./ScoringManager.sol");
var PrivateScoringManager = artifacts.require("./PrivateScoringManager.sol");
var AdministratorsRegistry = artifacts.require("./AdministratorsRegistry.sol");
var ExpertsRegistry = artifacts.require("./ExpertsRegistry.sol");
var ScoringsRegistry = artifacts.require("./ScoringsRegistry.sol");
var ScoringOffersManager = artifacts.require("./ScoringOffersManager.sol");
var RandomGenerator = artifacts.require("./RandomGenerator.sol");
var ArrayExtensions = artifacts.require("./ArrayExtensions.sol");
var ScoringParametersProvider = artifacts.require("./ScoringParametersProvider.sol");
var AllotmentEventsManager = artifacts.require("./AllotmentEventsManager.sol");
var AllotmentEvent = artifacts.require("./AllotmentEvent.sol");
var SmartValleyToken = artifacts.require("./SmartValleyToken.sol");
var SafeMath = artifacts.require("./SafeMath.sol");
var ContractExtensions = artifacts.require("./ContractExtensions.sol");

module.exports = function(deployer) {
  var hrAreaId = 1;
  var hrAreaMaxScore = 23;
  var hrAreaReward = 1;
  var hrCriterionIds =     [14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24];
  var hrCriterionWeights = [10, 10,  3,  4,  7,  3,  6,  5,  5,  2,  3];

  var analystAreaId = 2;
  var analystAreaMaxScore = 27;
  var analystAreaReward = 1;
  var analystCriterionIds =     [29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48];
  var analystCriterionWeights = [10, 10,  7,  5,  6,  2,  5,  2,  2,  5,  3, 10, 10,  7,  5,  3,  8,  5,  3,  5];

  var techAreaId = 3;
  var techAreaMaxScore = 17;
  var techAreaReward = 1;
  var techCriterionIds =     [25, 26, 27, 28];
  var techCriterionWeights = [5,  3, 10,  5];

  var lawyerAreaId = 4;
  var lawyerAreaMaxScore = 16;
  var lawyerAreaReward = 1;
  var lawyerCriterionIds =     [1,  2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
  var lawyerCriterionWeights = [10, 3, 1, 4, 4, 2, 8, 4, 8,  4,  7,  3,  3];

  var marketerAreaId = 5;
  var marketerAreaMaxScore = 17;
  var marketerAreaReward = 1;
  var marketerCriterionIds =     [49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68];
  var marketerCriterionWeights = [3,  7,  9,  9, 10,  6, 10,  9,  6,  4,  4,  4,  4,  6,  4,  6,  8,  3,  5,  7];

  var allotmentTokensFreezingDuration = 30;

  let scoringOffersManager;
  let expertsRegistry;
  let scoringsRegistry;
  let administratorsRegistry;
  let scoringParametersProvider;
  let scoringManager;
  let privateScoringManager;
  let token;

  deployer.deploy(RandomGenerator)
  .then(() => {
    deployer.link(RandomGenerator, ScoringOffersManager);
    return deployer.deploy(ContractExtensions);
  })
  .then(() => {
    deployer.link(ContractExtensions, SmartValleyToken);
    deployer.link(ContractExtensions, AllotmentEvent);
    return deployer.deploy(SafeMath);
  })
  .then(() => {
    deployer.link(SafeMath, SmartValleyToken);
    deployer.link(SafeMath, AllotmentEvent);
    return deployer.deploy(SmartValleyToken);
  })
  .then(tokenInstance => {
    token = tokenInstance;
    return deployer.deploy(AdministratorsRegistry);
  })
  .then(administratorsRegistryInstance => {
    administratorsRegistry = administratorsRegistryInstance;
    return deployer.deploy(ScoringParametersProvider, administratorsRegistry.address);
  })
  .then(scoringParametersProviderInstance => {
    scoringParametersProvider = scoringParametersProviderInstance;
    return scoringParametersProvider.initializeAreaParameters(
      hrAreaId,
      hrAreaMaxScore,
      hrAreaReward,
      hrCriterionIds,
      hrCriterionWeights);
  })
  .then(() => {
    return scoringParametersProvider.initializeAreaParameters(
      analystAreaId,
      analystAreaMaxScore,
      analystAreaReward,
      analystCriterionIds,
      analystCriterionWeights);
  })
  .then(() => {
    return scoringParametersProvider.initializeAreaParameters(
      techAreaId,
      techAreaMaxScore,
      techAreaReward,
      techCriterionIds,
      techCriterionWeights);
  })
  .then(() => {
    return scoringParametersProvider.initializeAreaParameters(
      lawyerAreaId,
      lawyerAreaMaxScore,
      lawyerAreaReward,
      lawyerCriterionIds,
      lawyerCriterionWeights);
  })
  .then(() => {
    return scoringParametersProvider.initializeAreaParameters(
      marketerAreaId,
      marketerAreaMaxScore,
      marketerAreaReward,
      marketerCriterionIds,
      marketerCriterionWeights);
  })
  .then(() => {
    return deployer.deploy(ArrayExtensions);
  })
  .then(() => {
    deployer.link(ArrayExtensions, ExpertsRegistry);
    return deployer.deploy(ExpertsRegistry, administratorsRegistry.address, scoringParametersProvider.address);
  })
  .then(expertsRegistryInstance => {
    expertsRegistry = expertsRegistryInstance;
    return deployer.deploy(ScoringsRegistry);
  })
  .then(scoringsRegistryInstance => {
    scoringsRegistry = scoringsRegistryInstance;
    return deployer.deploy(ScoringOffersManager, 3, 2, 2, expertsRegistry.address, administratorsRegistry.address, scoringsRegistry.address);
  })
  .then(scoringOffersManagerInstance => {
    scoringOffersManager = scoringOffersManagerInstance;
    return deployer.deploy(ScoringManager, scoringOffersManager.address, administratorsRegistry.address, scoringsRegistry.address, scoringParametersProvider.address);
  })
  .then((scoringManagerInstance) => {
    scoringManager = scoringManagerInstance;
    return scoringOffersManager.setScoringManager(scoringManagerInstance.address);
  })
  .then(() => {
    return deployer.deploy(PrivateScoringManager, scoringOffersManager.address, administratorsRegistry.address, scoringsRegistry.address, scoringParametersProvider.address);
  })
  .then((privateScoringManagerInstance) => {
    privateScoringManager = privateScoringManagerInstance;
    return scoringOffersManager.setPrivateScoringManager(privateScoringManager.address);
  })
  .then(() => {
    return scoringsRegistry.setPrivateScoringManager(privateScoringManager.address);
  })
  .then(() => {
    return scoringsRegistry.setScoringManager(scoringManager.address);
  })
  .then(() => {
    return scoringsRegistry.setScoringOffersManager(scoringOffersManager.address);
  })
  .then(() => {
    return deployer.deploy(AllotmentEventsManager, administratorsRegistry.address, allotmentTokensFreezingDuration, token.address);
  });
}