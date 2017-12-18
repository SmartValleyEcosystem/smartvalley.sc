var ProjectManager = artifacts.require("./ProjectManager.sol");
var SmartValleyToken = artifacts.require("./SmartValleyToken.sol");

module.exports = function(deployer) {
  var tokenInstance;
  SmartValleyToken.deployed()
  .then(function(t){
    tokenInstance = t;
    return deployer.deploy(ProjectManager, t.address, 120, 10);
  })
  .then(function(){
    return ProjectManager.deployed();
  })
  .then(function(pm){
    return tokenInstance.addKnownContract(pm.address);
  });
};
