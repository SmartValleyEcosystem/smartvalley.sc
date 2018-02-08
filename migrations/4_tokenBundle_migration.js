var SmartValleyTokenMock = artifacts.require("./mock/SmartValleyTokenMock.sol");
var BalanceFreezerMock = artifacts.require("./mock/BalanceFreezerMock.sol");
var MinterMock = artifacts.require("./mock/MinterMock.sol");
var VotingManagerMock = artifacts.require("./mock/VotingManagerMock.sol");
var ScoringManagerMock = artifacts.require("./mock/ScoringManagerMock.sol");

var SmartValleyToken = artifacts.require("./SmartValleyToken.sol");
var BalanceFreezer = artifacts.require("./BalanceFreezer.sol");
var Minter = artifacts.require("./Minter.sol");
var VotingManager = artifacts.require("./VotingManager.sol");
var ScoringManager = artifacts.require("./ScoringManager.sol");

module.exports = function(deployer) {

  var questions =      [1,  2, 3,   4,  5,  6, 7,  8,  9, 10, 11, 12, 13];
  var expertiseAreas = [1,  1, 1,   1,  4,  4, 2,  2,  2,  3,  3,  3,  3];
  var minScores =      [0,  0, 0, -15,  0,  0, 0,  0,  0,  0,  0,  0,  0];
  var maxScores =      [6, 10, 3,   0, 10, 15, 8, 10, 10,  7,  6,  5, 10];

  let freezer
  let token
  let voting
  let minter
  let scoring

  if(deployer.network.includes('mock_')) {     

    deployer.deploy(BalanceFreezerMock, {overwrite: false})
    .then(() => {
      return BalanceFreezerMock.deployed()
    })
    .then((freezerInstance) => {
      freezer = freezerInstance
      return deployer.deploy(SmartValleyTokenMock, freezer.address, [], 1000 * (10 ** 18), {overwrite: false})
    })
    .then(() => {
      return SmartValleyTokenMock.deployed()
    })
    .then((tokenInstance) => {
      token = tokenInstance
      return deployer.deploy(VotingManagerMock, freezer.address, token.address, 2, {overwrite: false})
    })
    .then(() => {
      return VotingManagerMock.deployed()
    })
    .then((votingInstance) => {
      voting = votingInstance
      voting.setAcceptanceThresholdPercent(50)
      return deployer.deploy(MinterMock, token.address, {overwrite: false})
    })
    .then(() => {
      return MinterMock.deployed()
    })
    .then((minterInstance) => {
      minter = minterInstance
      token.setMinter(minter.address)
      return deployer.deploy(ScoringManagerMock, token.address, 120, 10, minter.address, {overwrite: false})
    })
    .then(() => {
      return ScoringManagerMock.deployed()
    })
    .then((scoringInstance) => {
      scoring = scoringInstance
      minter.setScoringManagerAddress(scoring.address);  
      scoring.setQuestions(expertiseAreas, questions, minScores, maxScores);
      token.addKnownContract(scoring.address);
    })    

  } else {

    deployer.deploy(BalanceFreezer)
    .then(() => {
      return BalanceFreezer.deployed()
    })
    .then((freezerInstance) => {
      freezer = freezerInstance
      return deployer.deploy(SmartValleyToken, freezer.address)
    })
    .then(() => {
      return SmartValleyToken.deployed()
    })
    .then((tokenInstance) => {
      token = tokenInstance
      return deployer.deploy(VotingManager, freezer.address, token.address, 2)
    })
    .then(() => {
      return VotingManager.deployed()
    })
    .then((votingInstance) => {
      voting = votingInstance
      voting.setAcceptanceThresholdPercent(50)
      return deployer.deploy(Minter, token.address)
    })
    .then(() => {
      return Minter.deployed()
    })
    .then((minterInstance) => {
      minter = minterInstance
      token.setMinter(minter.address)
      return deployer.deploy(ScoringManager, token.address, 120, 10, minter.address)
    })
    .then(() => {
      return ScoringManager.deployed()
    })
    .then((scoringInstance) => {
      scoring = scoringInstance
      minter.setScoringManagerAddress(scoring.address);  
      scoring.setQuestions(expertiseAreas, questions, minScores, maxScores);
      token.addKnownContract(scoring.address);
    })     

  }

}