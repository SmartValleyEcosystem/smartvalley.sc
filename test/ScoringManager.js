var ScoringManagerMock = artifacts.require('./mock/ScoringManagerMock.sol');
var ScoringMock = artifacts.require('./mock/ScoringMock.sol');
var AdministratorsRegistryMock = artifacts.require('./mock/AdministratorsRegistryMock.sol');
var ExpertsRegistryMock = artifacts.require('./mock/ExpertsRegistryMock.sol');
var ScoringExpertsManagerMock = artifacts.require('./mock/ScoringExpertsManagerMock.sol');
var RandomGenerator = artifacts.require('./RandomGenerator.sol');

contract('ScoringManager', async function(accounts) {
    const areasCases = [2, 3, 4, 1, 12, 13, 14, 23, 24, 34, 123, 124, 234, 134, 1234];  
    let scoringManager, owner, external_id;
    let administratorsRegistry;
    let expertsRegistry;
    let randomGenerator;
    let scoringExpertsManager;  
     
    let areas = [ 1,  2,  3,  4,  5];
    let areasMaxScore =  [16, 23, 17, 27, 17];
    let areaEstimateRewards = [0.1, 0.1, 0.1, 0.1, 0.1];
    var areaExperts = [3, 3, 3, 3];     
    let expertList, expertAreasList;

    let isAccountGenerated = true;

    function randomNumber(min, max) {
        return Math.floor(Math.random() * (max - min)) + min
    }

    function getScoringCost() {
        cost = null;
        for (i = 0; i < areas.length; i++) {
            cost += areaExperts[i] * areaEstimateRewards[i];
        }        
        return web3.toWei(cost);
    }    

    beforeEach(async function(){
        owner = accounts[8];
        expertList = []
        expertAreasList = []
     
        administratorsRegistry = await AdministratorsRegistryMock.new({from: owner});
        expertsRegistry = await ExpertsRegistryMock.new(administratorsRegistry.address, areas, {from: owner});      
        randomGenerator = await RandomGenerator.new({from: owner});      
        scoringExpertsManager = await ScoringExpertsManagerMock.new(3, 2, expertsRegistry.address, administratorsRegistry.address, {from: owner});    
        
        rewardsWei = [];
        for (i = 0; i < areas.length; i++) {
            rewardsWei.push(web3.toWei(areaEstimateRewards[i], 'ether'))
        }        
        
        scoringManager = await ScoringManagerMock.new(scoringExpertsManager.address, administratorsRegistry.address, areas, rewardsWei, areasMaxScore, {from: owner});
     
        external_id = Math.floor(Math.random() * (100000000 - 1000000 + 1)) + 1000000;

        await administratorsRegistry.add(owner, {from: owner});        

        for (let i = 0; i < 20; i++) {      
            if (isAccountGenerated) {
                expertList.push(accounts[i + 10])
            } else {
                expertList.push(await web3.personal.newAccount());
            }            
            expertAreasList.push(areasCases[randomNumber(0, areasCases.length - 1)]);
        }

        await expertsRegistry.addExperts(expertList, expertAreasList);
        
        await scoringExpertsManager.setScoringManager(scoringManager.address, {from: owner});        
    });

    it('project shouldn\'t created if ether not enough' , async function() {              
        let error = null;
        try {
            await scoringManager.start(external_id, areas, areaExperts, {from: accounts[9], value: web3.toWei(0.1)});
        } catch (e){
            console.log('ERROR: ' + e);
            error = e;
        }

        assert.notEqual(error, null, 'error should be thrown');
    });

    it('start -> add new project with ext_id : get project address from mapping and check project contract', async function() {      
        var scoringCreationCost = getScoringCost();
        await scoringManager.start(external_id, areas, areaExperts, {from: owner, value: scoringCreationCost});      
        var projectAddressFromMapping = await scoringManager.scoringsMap(external_id);
        var projectAddressFromArray = await scoringManager.scorings(0);

        assert.notEqual(projectAddressFromMapping, '0x0000000000000000000000000000000000000000', 'mapping not contain project id -> address');
        assert.equal(projectAddressFromArray, projectAddressFromMapping, 'projects array not contain project address');

        var scoring = ScoringMock.at(projectAddressFromArray);
        var address = await scoring.author();

        var balance = await web3.eth.getBalance(scoring.address);      

        assert.equal(+balance, scoringCreationCost, scoringCreationCost + 'project balance exptected');     
        assert.equal(address.toLowerCase(), owner, 'project author address is not an account[8]');
    });

    it.only('expert should send estimates by area to scoring', async function() {
        const owner = accounts[5];            
        
        await scoringManager.start(external_id, areas, areaExperts, {from: owner, value: web3.toWei(1.2, 'ether')});
        console.log('start scoring success');

        const offers = await scoringExpertsManager.getOffers(external_id);

        const exp_area = parseInt(offers[0][0])
        const exp_address = offers[1][0]

        await web3.personal.unlockAccount(exp_address)

        await web3.eth.sendTransaction({from: accounts[0], to: exp_address, value: web3.toWei(0.2, "ether")});

        console.log('expert ready to work')

        await scoringExpertsManager.accept(external_id, exp_area, {from: exp_address});

        console.log('expert accepted')

        const area = exp_area;
        const q = [1,2,3,4];
        const e = [0,0,0,0];
        const comm = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3"), web3.sha3("qqq4")];
        
        await scoringManager.submitEstimates(external_id, area, q, e, comm, {from: exp_address});
        console.log('estimation sucess')
        //const bal = await web3.eth.getBalance(expert)
        //console.log('balance', bal)
    })
});
