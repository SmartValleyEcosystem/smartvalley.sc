var ProjectManager = artifacts.require("./ProjectManager.sol");
var SmartValleyToken = artifacts.require("./SmartValleyToken.sol");
var Scoring = artifacts.require("./Scoring.sol");

module.exports = function(deployer) {
  var tokenInstance;
  SmartValleyToken.deployed()
  .then(function(t){
    tokenInstance = t;
    return Scoring.deployed();
  })
  .then(function(s) {
    return deployer.deploy(ProjectManager, tokenInstance.address, 120, 10, s.address);
  })
  .then(function(){
    return ProjectManager.deployed();
  })
  .then(function(pm){
    return tokenInstance.addKnownContract(pm.address);
  });
};
