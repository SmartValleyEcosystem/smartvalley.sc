var SmartValleyToken = artifacts.require("./Crowdfunding/SmartValleyToken.sol");

module.exports = function(deployer) {
  deployer.deploy(SmartValleyToken);
};
