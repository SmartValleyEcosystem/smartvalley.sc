var web3 = require('web3');
var abi = [{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"author","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_owner","type":"address"}],"name":"changeOwner","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[],"name":"confirmOwner","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"newOwner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"inputs":[{"name":"_author","type":"address"},{"name":"_name","type":"string"}],"payable":false,"stateMutability":"nonpayable","type":"constructor"}];
var ProjectManager = artifacts.require('./ProjectManager.sol');

contract('ProjectManager', async function(accounts) {

    const projectManagerInitialParams = {};
    
        let manager;
    
        beforeEach(async function(){
            manager = await ProjectManager.new(...Object.values(projectManagerInitialParams));
        });
        
        it('addProject -> add new project with ext_id : get project address from mapping and check project contract', async function() {
            var external_id = web3.utils.hexToNumberString(web3.utils.randomHex(16));
            var projectName = 'test project';            
            
            await manager.addProject(external_id, projectName);
            var projectAddressFromMapping = await manager.projectsMap(external_id);
            var projectAddressFromArray = await manager.projects(0);

            assert.notEqual(projectAddressFromMapping, '0x0000000000000000000000000000000000000000', 'mapping not contain project id -> address');
            assert.equal(projectAddressFromArray, projectAddressFromMapping, 'projects array not contain project address');
            
            var v = new web3(new web3.providers.HttpProvider("http://localhost:8545"));
            var contract = new v.eth.Contract(abi, projectAddressFromMapping);            

            var name = await contract.methods.name().call();
            var address = await contract.methods.author().call();            

            assert.equal(name, projectName, 'project name not expected');
            assert.equal(address.toLowerCase(), accounts[0], 'project author address is not an account[0]');
        });        
});