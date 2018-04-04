var EtherManagerMock = artifacts.require("./mock/EtherManagerMock.sol");
var EtherManager = artifacts.require("./EtherManager.sol");

module.exports = function(deployer) {
  if(deployer.network.includes('mock_')) {
    deployer.deploy(EtherManagerMock, {overwrite: false});
  } else {
    deployer.deploy(EtherManager);
  }
}