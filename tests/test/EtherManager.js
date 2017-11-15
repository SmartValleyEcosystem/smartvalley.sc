var EtherManager = artifacts.require("./EtherManager.sol");

contract('EtherManager', function(accounts) {

    const ehterManagerInitialParams = {};

    let manager;    

    beforeEach(async function(){        
        manager = await EtherManager.new(...Object.values(ehterManagerInitialParams), {
            value: web3.toWei(3, 'ether')
        });                
    });

    
    it("setAmountToGift -> get weiAmountToGift : result - 1e+18 wei", async function() {                
        var actual_val = await manager.weiAmountToGift();
        assert.equal(actual_val, 1000000000000000000, 'amountToGift is not equal 1e+18 wei, actual: ' + actual_val);        
    });

    it("setAmountToGift -> set 5e+18 wei and get weiAmountToGift : result - 5e+18 wei ", async function() {
        var newVal = 5000000000000000000;
        await manager.setAmountToGift(newVal);   

        var actual_val = await manager.weiAmountToGift();
        assert.equal(actual_val, newVal, 'amountToGift is not equal 5e+18 wei, actual: ' + actual_val);
    });          

    it("setAmountToGift -> set 0, catch ecxeption and get weiAmountToGift : result - 1e+18 wei", async function() {
        var newVal = 0;
        var error = '';        
        try{
            await manager.setAmountToGift(newVal);
        }
        catch (e){
            error = e.message;            
        }        
        

        var actual_val = await manager.weiAmountToGift();
        assert.equal(error, 'VM Exception while processing transaction: revert', 'revert error must be returned');            
        assert.equal(actual_val, 1000000000000000000, 'amountToGift is not equal 1e+18 wei, actual: ' + actual_val);
    });

    it("setAmountToGift -> try set wei from not Owner, catch ecxeption and get weiAmountToGift : result - 1e+18 wei", async function() {
        var newVal = 3000000000000000000;
        var error = '';
        
        try{
            await manager.setAmountToGift(newVal, {from: accounts[1]});
        }
        catch (e){
            error = e.message;            
        }        
        

        assert.equal(error, 'VM Exception while processing transaction: revert', 'revert error must be returned');            
        assert.equal(await manager.weiAmountToGift(), 1000000000000000000);
    });

    it("giftEth -> gift 1 ether to account #4 : balance decreased, account #4 added in receiversMap and receivers", async function(){        
        var actual_balance = web3.eth.getBalance(manager.address);             
        assert.isNotTrue(await manager.receiversMap(accounts[4]), 'receiversMap contain \'account #4 => true\'');

        await manager.giftEth(accounts[4]);        

        var new_balance = web3.eth.getBalance(manager.address);
        assert.equal(new_balance, actual_balance - 1000000000000000000, 'contract balancr in not decreased: expected ' + actual_balance + ', actual ' + new_balance);                
        assert.isTrue(await manager.receiversMap(accounts[4]), 'receiversMap is not contain \'account #4 => true\'');
        assert.equal(await manager.receivers(0), accounts[4], 'receivers array is not contain \'account #4\'');        
    });

    it("giftEth -> try gift 1 ether to account #4 again : throw error, balance not changed", async function(){                        
        await manager.giftEth(accounts[4]);        
        var actual_balance = web3.eth.getBalance(manager.address);
        var error = '';

        try{
            await manager.giftEth(accounts[4]);
        }
        catch (e){
            error = e.message;
        }  
        
        var new_balance = web3.eth.getBalance(manager.address);
        assert.equal(error, 'VM Exception while processing transaction: revert', 'revert error must be returned');                        
        assert.equal(new_balance + 0, actual_balance + 0, 'contract balance is changed: expected ' + actual_balance + ', actual ' + new_balance); //todo remove + 0 ???        
    });

    it("giftEth -> try gift erher from not Owner : throw error, balance not changed", async function(){
        var actual_balance = web3.eth.getBalance(manager.address);
        var error = '';

        try{
            await manager.giftEth(accounts[4], {from: accounts[2]});
        }
        catch (e){
            error = e.message;
        }

        var new_balance = web3.eth.getBalance(manager.address);
        assert.equal(error, 'VM Exception while processing transaction: revert', 'revert error must be returned');
        assert.equal(new_balance + 0, actual_balance + 0, 'contract balance is changed: expected ' + actual_balance + ', actual ' + new_balance); //todo remove + 0 ???  
        
    });

    it("owner -> get default owner : account #0 is owner ", async function(){
        assert.equal(await manager.owner(), accounts[0], 'account #0 is not owner');
    });

    it("changeOwner -> confirmOwner -> account #0 call change owner, account #1 cofirm : account #2 is owner", async function(){
        var new_owner_account_1 = accounts[1];

        await manager.changeOwner(new_owner_account_1);
        var newOwner = await manager.newOwner()
        assert.equal(newOwner, new_owner_account_1, 'new owner is not account #1: actual ' + newOwner);
        await manager.confirmOwner({from: new_owner_account_1});
        assert.equal(await manager.owner(), new_owner_account_1, 'account #1 is not owner');
    });
    
});