var EtherManagerMock = artifacts.require('./mock/EtherManagerMock.sol');

contract('EtherManager', function(accounts) {  

    let manager;
    let owner;

    beforeEach(async function() {        
        owner = accounts[0];                

        manager = await EtherManagerMock.new({
            from: owner,
            value: web3.toWei(3, 'ether')
        });                        
    });

    
    it("weiAmountToGift -> get default weiAmountToGift : result - 1e+18 wei", async function() {                
        var actual_val = await manager.weiAmountToGift();
        assert.equal(actual_val, web3.toWei(1, 'ether'), 'amountToGift is not equal 1e+18 wei, actual: ' + actual_val);
    });

    it("setAmountToGift -> set 5e+18 wei and get weiAmountToGift : result - 5e+18 wei ", async function() {
        var newVal = web3.toWei(5, 'ether');
        await manager.setAmountToGift(newVal, {from: owner});

        var actual_val = await manager.weiAmountToGift();
        assert.equal(actual_val, newVal, 'amountToGift is not equal 5e+18 wei, actual: ' + actual_val);
    });          

    it("setAmountToGift -> set 0, catch ecxeption and get weiAmountToGift : result - 1e+18 wei", async function() {     
        var newVal = web3.toWei(0, 'ether');   
        var error = null;        
        try{
            await manager.setAmountToGift(newVal, {from: owner});            
        }
        catch (e){            
            error = e.message;            
        }        
        
        var actual_val = await manager.weiAmountToGift();

        assert.notEqual(error, null, 'Error must be returned');
        assert.equal(actual_val, web3.toWei(1, 'ether'), 'amountToGift is not equal 1e+18 wei, actual: ' + actual_val);
    });

    it("setAmountToGift -> try set wei from not Owner, catch ecxeption and get weiAmountToGift : result - 1e+18 wei", async function() {
        var newVal = web3.toWei(3, 'ether');
        var error = null;
        
        try{
            await manager.setAmountToGift(newVal, { from: accounts[1] });
        }
        catch (e){
            error = e.message;            
        }        
        
        assert.notEqual(error, null, 'Error must be returned');
        assert.equal(await manager.weiAmountToGift(), web3.toWei(1, 'ether'));
    });

    it("giftEth -> gift 1 ether to account #4 : balance decreased, account #4 added in receiversMap and receivers", async function(){        
        var actual_balance = web3.eth.getBalance(manager.address);
        assert.isNotTrue(await manager.receiversMap(accounts[4]), 'receiversMap contain \'account #4 => true\'');

        await manager.giftEth(accounts[4], { from: owner });

        var new_balance = web3.eth.getBalance(manager.address);

        assert.equal(new_balance, actual_balance - web3.toWei(1, 'ether'), 'contract balancr in not decreased: expected ' + actual_balance + ', actual ' + new_balance);                
        assert.isTrue(await manager.receiversMap(accounts[4]), 'receiversMap is not contain \'account #4 => true\'');
        assert.equal(await manager.receivers(0), accounts[4], 'receivers array is not contain \'account #4\'');        
    });

    it("giftEth -> try gift 1 ether to account #4 again : throw error, balance not changed", async function(){                        
        await manager.giftEth(accounts[4], { from: owner });        
        var actual_balance = web3.eth.getBalance(manager.address);
        var error = null;

        try{
            await manager.giftEth(accounts[4], { from: owner });
        }
        catch (e){
            error = e.message;
        }  
        
        var new_balance = web3.eth.getBalance(manager.address);

        assert.notEqual(error, null, 'Error must be returned');
        assert.equal(new_balance + 0, actual_balance + 0, 'contract balance is changed: expected ' + actual_balance + ', actual ' + new_balance); //todo remove + 0 ???        
    });

    it("giftEth -> try gift erher from not Owner : throw error, balance not changed", async function(){
        var actual_balance = web3.eth.getBalance(manager.address);
        var error = null;

        try{
            await manager.giftEth(accounts[4], {from: accounts[2]});
        }
        catch (e){
            error = e.message;
        }

        var new_balance = web3.eth.getBalance(manager.address);
        
        assert.notEqual(error, null, 'Error must be returned');
        assert.equal(new_balance + 0, actual_balance + 0, 'contract balance is changed: expected ' + actual_balance + ', actual ' + new_balance); //todo remove + 0 ???  
        
    });

    it("owner -> get default Owner : account #0 is owner ", async function(){
        assert.equal(await manager.owner(), owner, 'account #0 is not owner');
    });

    it("changeOwner -> confirmOwner -> Owner call change owner, account #1 cofirm : account #1 is owner", async function(){
        var new_owner_account_1 = accounts[1];        
        
        await manager.changeOwner(new_owner_account_1, { from: owner });
        var newOwner = await manager.newOwner();
        assert.equal(newOwner, new_owner_account_1, 'new owner is not account #1: actual ' + newOwner);
        await manager.confirmOwner({from: new_owner_account_1});
        assert.equal(await manager.owner(), new_owner_account_1, 'account #1 is not owner');
    });
    
});