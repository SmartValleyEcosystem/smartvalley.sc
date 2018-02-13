var ScoringManagerMock = artifacts.require('./mock/ScoringManagerMock.sol');
var ScoringMock = artifacts.require('./mock/ScoringMock.sol');
var SmartValleyTokenMock = artifacts.require("./mock/SmartValleyTokenMock.sol");
var BalanceFreezerMock = artifacts.require("./mock/BalanceFreezerMock.sol");
var MinterMock = artifacts.require('./mock/MinterMock.sol');
var AdministratorsRegistryMock = artifacts.require('./mock/AdministratorsRegistryMock.sol');
var ExpertsRegistryMock = artifacts.require('./mock/ExpertsRegistryMock.sol');
var ScoringExpertsManagerMock = artifacts.require('./mock/ScoringExpertsManagerMock.sol');
var RandomGenerator = artifacts.require('./RandomGenerator.sol');

contract('ScoringManager', async function(accounts) {

    let manager, token, balanceFreezer, minter, owner, external_id;
    let administratorsRegistry;
    let expertsRegistry;
    let randomGenerator;
    let scoringExpertsManager;
    let amount = 120 * (10 ** 18);
    let scoringCreationCost = 120;
    let estimateReward = 10;
    let areas = [1, 2, 3, 4];
    var areaExperts = [3, 3, 3, 3];

    beforeEach(async function(){
        owner = accounts[8];

        balanceFreezer = await BalanceFreezerMock.new({from: owner});
        administratorsRegistry = await AdministratorsRegistryMock.new({from: owner});
        expertsRegistry = await ExpertsRegistryMock.new(administratorsRegistry.address, areas, {from: owner});
        randomGenerator = await RandomGenerator.new({from: owner});
        scoringExpertsManager = await ScoringExpertsManagerMock.new(3, 2, expertsRegistry.address, {from: owner});
        token = await SmartValleyTokenMock.new(balanceFreezer.address, [owner], amount, {from: owner});
        minter = await MinterMock.new(token.address, {from: owner});
        manager = await ScoringManagerMock.new(token.address, scoringCreationCost, estimateReward, minter.address, scoringExpertsManager.address, {from: owner});

        external_id = Math.floor(Math.random() * (100000000 - 1000000 + 1)) + 1000000;

        await token.addKnownContract(manager.address, {from: owner});
        await token.setMinter(minter.address, {from: owner});
        await scoringExpertsManager.setScoringManager(manager.address, {from: owner});
        await minter.setScoringManagerAddress(manager.address, {from: owner});
    });

    it('project shouldn\'t created if tokens not enough' , async function() {
        let error = null;
        try {
            await manager.start(external_id, areas, areaExperts, {from: accounts[5]});
        } catch (e){
            console.log('ERROR: ' + e);
            error = e;
        }

        assert.notEqual(error, null, 'error should be thrown');
    });

    it('start -> add new project with ext_id : get project address from mapping and check project contract', async function() {
        await manager.start(external_id, areas, areaExperts, {from: owner});
        var projectAddressFromMapping = await manager.scoringsMap(external_id);
        var projectAddressFromArray = await manager.scorings(0);

        assert.notEqual(projectAddressFromMapping, '0x0000000000000000000000000000000000000000', 'mapping not contain project id -> address');
        assert.equal(projectAddressFromArray, projectAddressFromMapping, 'projects array not contain project address');

        var scoring = ScoringMock.at(projectAddressFromArray);
        var address = await scoring.author();

        var balance = await token.balanceOf(projectAddressFromArray);
        var scoringCreationCostWei = scoringCreationCost * (10 ** 18);

        assert.equal(+balance, scoringCreationCostWei, scoringCreationCostWei + 'project balance exptected');     
        assert.equal(address.toLowerCase(), owner, 'project author address is not an account[8]');
    });
});