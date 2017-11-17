var EtherManager = artifacts.require("./EtherManager.sol");

module.exports = function(deployer) {
  deployer.deploy(EtherManager);
};
