var VotingManager = artifacts.require("./VotingManager.sol");

module.exports = function(deployer) {
  deployer.deploy(VotingManager);
};
