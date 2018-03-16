var ScoringManagerMock = artifacts.require('./mock/ScoringManagerMock.sol');
var ScoringMock = artifacts.require('./mock/ScoringMock.sol');
var AdministratorsRegistryMock = artifacts.require('./mock/AdministratorsRegistryMock.sol');
var ExpertsRegistryMock = artifacts.require('./mock/ExpertsRegistryMock.sol');
var ScoringExpertsManagerMock = artifacts.require('./mock/ScoringExpertsManagerMock.sol');
var RandomGenerator = artifacts.require('./RandomGenerator.sol');

contract('ScoringManager', async function(accounts) {

    let manager, owner, external_id;
    let administratorsRegistry;
    let expertsRegistry;
    let randomGenerator;
    let scoringExpertsManager;   
    let scoringCreationCost = 12;
    let estimateReward = 1;
    let areas = [1, 2, 3, 4];
    var areaExperts = [3, 3, 3, 3];    

    beforeEach(async function(){
        owner = accounts[8];
     
        administratorsRegistry = await AdministratorsRegistryMock.new({from: owner});
        expertsRegistry = await ExpertsRegistryMock.new(administratorsRegistry.address, areas, {from: owner});      
        randomGenerator = await RandomGenerator.new({from: owner});      
        scoringExpertsManager = await ScoringExpertsManagerMock.new(3, 2, expertsRegistry.address, administratorsRegistry.address, {from: owner});           
        manager = await ScoringManagerMock.new(scoringCreationCost, estimateReward, scoringExpertsManager.address, {from: owner});
      
        external_id = Math.floor(Math.random() * (100000000 - 1000000 + 1)) + 1000000;

        await administratorsRegistry.add(owner, {from: owner});

        await expertsRegistry.add(accounts[0], areas, {from: owner});
        await expertsRegistry.add(accounts[1], areas, {from: owner});
        await expertsRegistry.add(accounts[2], areas, {from: owner});
        await expertsRegistry.add(accounts[3], areas, {from: owner});
        
        await scoringExpertsManager.setScoringManager(manager.address, {from: owner});        
    });

    it('project shouldn\'t created if ether not enough' , async function() {              
        let error = null;
        try {
            await manager.start(external_id, areas, areaExperts, {from: accounts[9], value: web3.toWei(1)});
        } catch (e){
            console.log('ERROR: ' + e);
            error = e;
        }

        assert.notEqual(error, null, 'error should be thrown');
    });

    it('start -> add new project with ext_id : get project address from mapping and check project contract', async function() {      
        await manager.start(external_id, areas, areaExperts, {from: owner, value: web3.toWei(scoringCreationCost)});      
        var projectAddressFromMapping = await manager.scoringsMap(external_id);
        var projectAddressFromArray = await manager.scorings(0);

        assert.notEqual(projectAddressFromMapping, '0x0000000000000000000000000000000000000000', 'mapping not contain project id -> address');
        assert.equal(projectAddressFromArray, projectAddressFromMapping, 'projects array not contain project address');

        var scoring = ScoringMock.at(projectAddressFromArray);
        var address = await scoring.author();

        var balance = await web3.eth.getBalance(scoring.address);
        var scoringCreationCostWei = web3.toWei(scoringCreationCost);

        assert.equal(+balance, scoringCreationCostWei, scoringCreationCostWei + 'project balance exptected');     
        assert.equal(address.toLowerCase(), owner, 'project author address is not an account[8]');
    });
});