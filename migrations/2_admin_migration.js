var AdministratorsRegistry = artifacts.require("./AdministratorsRegistry.sol");

module.exports = function(deployer) {    
  deployer.deploy(AdministratorsRegistry);    
}
