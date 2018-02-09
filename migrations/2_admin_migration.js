var AdministratorsRegistry = artifacts.require("./AdministratorsRegistry.sol");
var ExpertsRegistry = artifacts.require("./ExpertsRegistry.sol");
var ExpertsSelector = artifacts.require("./ExpertsSelector.sol");

module.exports = function(deployer) {
  deployer.deploy(AdministratorsRegistry)
  .then(function() {
    return AdministratorsRegistry.deployed();
  })
  .then(function(administratorsRegistryInstance) {
    let areas = [1, 2, 3, 4];
    return deployer.deploy(ExpertsRegistry, administratorsRegistryInstance.address, areas);
  })
  .then(function() {
    return ExpertsRegistry.deployed();
  })
  .then(function(expertsRegistryInstance) {
    return deployer.deploy(ExpertsSelector, expertsRegistryInstance.address);
  });
}
