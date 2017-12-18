var ProjectManagerMock = artifacts.require('./mock/ProjectManagerMock.sol');
var ProjectMock = artifacts.require('./mock/ProjectMock.sol');
var SmartValleyTokenMock = artifacts.require("./mock/SmartValleyTokenMock.sol");

contract('ProjectManager', async function(accounts) {

    let manager;
    let token;
    let owner;
    let amount = 120 * (10 ** 18);
    let projectCreationCost = 120;
    let external_id;
    let projectName;

    beforeEach(async function(){
        owner = accounts[8];
        token = await SmartValleyTokenMock.new(owner, amount, {from: owner});
        manager = await ProjectManagerMock.new(token.address, projectCreationCost, accounts[9]);
        projectName = 'test project';
        external_id = Math.floor(Math.random() * (100000000 - 1000000 + 1)) + 1000000;
        await token.addKnownContract(manager.address, {from: owner});
    });

    it('project shouldn\'t created if tokens not enough' , async function() {
        let error = null;
        try {
            await manager.addProject(external_id, projectName, {from: accounts[5]});
        } catch (e){
            error = e;
        }
      
        assert.notEqual(error, null, 'error should be thrown');
    });
    
    it('addProject -> add new project with ext_id : get project address from mapping and check project contract', async function() {

        await manager.addProject(external_id, projectName, {from: owner});
        var projectAddressFromMapping = await manager.projectsMap(external_id);
        var projectAddressFromArray = await manager.projects(0);

        assert.notEqual(projectAddressFromMapping, '0x0000000000000000000000000000000000000000', 'mapping not contain project id -> address');
        assert.equal(projectAddressFromArray, projectAddressFromMapping, 'projects array not contain project address');

        var project = ProjectMock.at(projectAddressFromArray);
        var name = await project.name();
        var address = await project.author();
        
        var balance = await token.balanceOf(projectAddressFromArray);
        var projectCreationCostWei = projectCreationCost * (10 ** 18);

        assert.equal(+balance, projectCreationCostWei, projectCreationCostWei + 'project balance exptected');
        assert.equal(name, projectName, 'project name not expected');
        assert.equal(address.toLowerCase(), accounts[8], 'project author address is not an account[8]');
    });        
});