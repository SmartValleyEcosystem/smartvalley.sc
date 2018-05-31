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
    let previousExpertsRegistryAddress = "";
    let expertsRegistryInstance;

    deployer.deployed(ExpertsRegistry)
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