var SmartValleyToken = artifacts.require("./SmartValleyToken.sol");

module.exports = function(deployer) {
  deployer.deploy(SmartValleyToken);
};
