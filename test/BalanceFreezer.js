var BalanceFreezerMock = artifacts.require("./mock/BalanceFreezerMock.sol");

contract('BalanceFreezer', async function (accounts) {  
    let freezer;

    beforeEach(async function () {
        freezer = await BalanceFreezerMock.new();         
    });

    it('Should return correct frozen amount', async function () {       
       
        await freezer.freeze(500, 1, {from: accounts[1]});
        await freezer.freeze(500, 1, {from: accounts[1]});
        await freezer.freeze(500, 1, {from: accounts[2]});        
      
        var frozenAmount1 = await freezer.getFrozenAmount(accounts[1]);
        var frozenAmount2 = await freezer.getFrozenAmount(accounts[2]);   

        assert.equal(frozenAmount1, 1000, 'FrozenAmount for acc1 should be equal to 1000 , actual: ' + frozenAmount1);
        assert.equal(frozenAmount2, 500, 'FrozenAmount for acc2 should be equal to 500 , actual: ' + frozenAmount2);
    });
});
