var ScoringManager = artifacts.require("./ScoringManager.sol");
var PrivateScoringManager = artifacts.require("./PrivateScoringManager.sol");
var AdministratorsRegistry = artifacts.require("./AdministratorsRegistry.sol");
var ExpertsRegistry = artifacts.require("./ExpertsRegistry.sol");
var ScoringsRegistry = artifacts.require("./ScoringsRegistry.sol");
var ScoringOffersManager = artifacts.require("./ScoringOffersManager.sol");
var RandomGenerator = artifacts.require("./RandomGenerator.sol");
var ArrayExtensions = artifacts.require("./ArrayExtensions.sol");
var ScoringParametersProvider = artifacts.require("./ScoringParametersProvider.sol");

module.exports = function(deployer) {
    let previousExpertsRegistryAddress = "0xbafd0b26fe99a57d79060ef4c3a165d72b5bb1f8";
    let expertsRegistryInstance;

    if (!previousExpertsRegistryAddress) {
        return;
    }

    ExpertsRegistry.deployed()
    .then(expertsRegistry => {
        expertsRegistryInstance = expertsRegistry;
        return expertsRegistry.setMigrationHost(previousExpertsRegistryAddress);
    })
    .then(() => {
        return expertsRegistry.migrateFromHost(1);
    })
    .then(() => {
        return expertsRegistry.migrateFromHost(2);
    })
    .then(() => {
        return expertsRegistry.migrateFromHost(3);
    })
    .then(() => {
        return expertsRegistry.migrateFromHost(4);
    })
    .then(() => {
        return expertsRegistry.migrateFromHost(5);
    })
}