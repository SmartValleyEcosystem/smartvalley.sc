var AdministratorsRegistryMock = artifacts.require('./mock/AdministratorsRegistryMock.sol');
var ExpertsRegistryMock = artifacts.require('./mock/ExpertsRegistryMock.sol');
var ExpertsSelectorMock = artifacts.require('./mock/ExpertsSelectorMock.sol');

contract('ExpertsSelector', async function(accounts) {
    let owner;
    let admin;

    let expertsRegistry;
    let expertsSelector;

    beforeEach(async function(){
        owner = accounts[9];
        admin = accounts[8];

        let administratorsRegistry = await AdministratorsRegistryMock.new({from: owner});
        administratorsRegistry.add(admin, {from: owner});

        let areas = [1, 2, 3, 4, 5];
        expertsRegistry = await ExpertsRegistryMock.new(administratorsRegistry.address, areas, {from: owner});
        expertsSelector = await ExpertsSelectorMock.new(expertsRegistry.address, {from: owner});
    });

    it('experts are randomly selected when total experts count is bigger than requested' , async function() {

        var requestedExpertsCount = 9;
        var totalExpertsCount = 12;
        var addresses = [];
        for (let i = 0; i < totalExpertsCount; i++) {
            var address = web3.personal.newAccount();
            addresses.push(address);
            await expertsRegistry.add(address, [1], {from: admin});
        }

        var result = await expertsSelector.select(requestedExpertsCount, 1);
        for(var i = 0; i < requestedExpertsCount; i++) {
            console.log(`${i}: ${result[i]}, account index: ${addresses.indexOf(result[i])}`);
        }

        assert.equal(result.length, requestedExpertsCount);
        var unique = result.filter((v, i, a) => a.indexOf(v) === i);
        assert.equal(unique.length, requestedExpertsCount);
    });
});