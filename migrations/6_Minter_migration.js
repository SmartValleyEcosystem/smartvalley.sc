var Minter = artifacts.require("./Minter.sol");
var SmartValleyToken = artifacts.require("./SmartValleyToken.sol");

module.exports = function(deployer) {
  var tokenInstance;
  SmartValleyToken.deployed()
  .then(function(t){
    tokenInstance = t;
    return deployer.deploy(Minter, t.address);
  })
  .then(function(){
    return Minter.deployed();
  })
  .then(function(minterInstance){
    return tokenInstance.setMinter(minterInstance.address);
  });
};
