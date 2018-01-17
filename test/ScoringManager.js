var ScoringManagerMock = artifacts.require('./mock/ScoringManagerMock.sol');
var ScoringMock = artifacts.require('./mock/ScoringMock.sol');
var SmartValleyTokenMock = artifacts.require("./mock/SmartValleyTokenMock.sol");
var BalanceFreezerMock = artifacts.require("./mock/BalanceFreezerMock.sol");

contract('ScoringManager', async function(accounts) {

    let manager;
    let token;
    let owner;
    let amount = 120 * (10 ** 18);
    let scoringCreationCost = 120;
    let external_id; 

    beforeEach(async function(){
        owner = accounts[8];

        balanceFreezer = await BalanceFreezerMock.new();       
        token = await SmartValleyTokenMock.new(owner, amount, {from: owner});     
        manager = await ScoringManagerMock.new(token.address, scoringCreationCost);   

        external_id = Math.floor(Math.random() * (100000000 - 1000000 + 1)) + 1000000;

        await token.setBalanceFreezer(balanceFreezer.address, {from: owner});
        await token.addKnownContract(manager.address, {from: owner});
    });

    it('project shouldn\'t created if tokens not enough' , async function() {
        let error = null;
        try {
            await manager.start(external_id, {from: accounts[5]});
        } catch (e){
            error = e;
        }
      
        assert.notEqual(error, null, 'error should be thrown');
    });
    
    it('start -> add new project with ext_id : get project address from mapping and check project contract', async function() {
       
     
        await manager.start(external_id, {from: owner});
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