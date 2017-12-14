var EtherManagerMock = artifacts.require('./mock/EtherManagerMock.sol');

contract('EtherManager test plan', function(accounts) {  

    let manager;
    let owner;    

    beforeEach('deploy contract', async function() {        
        owner = accounts[9];                

        manager = await EtherManagerMock.new({
            from: owner,
            value: web3.toWei(10, 'ether')
        });                        
    });

    afterEach('sent ether back to owner', async function() {                
        manager.withdrawEth({from: owner});
    });

    it("amaountToGift: get default weiAmountToGift, result - 1e+18 wei", async function() {                
        var actual_val = await manager.weiAmountToGift();
        assert.equal(actual_val, web3.toWei(1, 'ether'), 'amountToGift is incorrect');
    });

    it("amaountToGift: set 5e+18 wei and get weiAmountToGift, result - 5e+18 wei ", async function() {
        var newVal = web3.toWei(5, 'ether');
        await manager.setAmountToGift(newVal, {from: owner});

        var actual_val = await manager.weiAmountToGift();
        assert.equal(actual_val, newVal, 'amountToGift is incorrect');
    });         
    
    it("amaountToGift: try set 0 wei, catch ecxeption and get weiAmountToGift, result - 1e+18 wei", async function() {     
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
        assert.equal(actual_val, web3.toWei(1, 'ether'), 'amountToGift is incorrect');
    });

    it("amaountToGift: try set wei from not Owner, catch ecxeption and get weiAmountToGift, result - 1e+18 wei", async function() {
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

    it("giftEther: gift 1 ether to account #4, balance decreased, account #4 added in receiversMap and receivers", async function(){        
        var actual_balance = web3.eth.getBalance(manager.address);
        assert.isNotTrue(await manager.receiversMap(accounts[4]), 'receiversMap contain \'account #4 => true\'');

        await manager.giftEth(accounts[4], { from: owner });

        var new_balance = web3.eth.getBalance(manager.address);    
        assert.equal(new_balance, actual_balance - web3.toWei(1, 'ether'), 'contract balance in not decreased');                
        assert.isTrue(await manager.receiversMap(accounts[4]), 'receiversMap is not contain \'account #4 => true\'');
        assert.equal(await manager.receivers(0), accounts[4], 'receivers array is not contain \'account #4\'');        
    });  

    it("giftEther: try gift 1 ether to account #4 again, catch ecxeption, balance not changed", async function(){                        
        await manager.giftEth(accounts[4], { from: owner });        
        var actual_balance = (web3.eth.getBalance(manager.address)).toString();
        var error = null;

        try{
            await manager.giftEth(accounts[4], { from: owner });
        }
        catch (e){
            error = e.message;
        }  
        
        var new_balance = (web3.eth.getBalance(manager.address)).toString();

        assert.notEqual(error, null, 'Error must be returned');
        assert.equal(new_balance, actual_balance, 'contract balance is changed');
    });

    it("giftEther: try gift erher from not Owner, catch ecxeption, balance not changed", async function(){
        var actual_balance = (web3.eth.getBalance(manager.address)).toString();
        var error = null;

        try{
            await manager.giftEth(accounts[4], {from: accounts[2]});
        }
        catch (e){
            error = e.message;
        }

        var new_balance = (web3.eth.getBalance(manager.address)).toString();
        
        assert.notEqual(error, null, 'Error must be returned');
        assert.equal(new_balance, actual_balance, 'contract balance is changed');
        
    });

    it("withdrawEth: call from Owner, get all ether back to account #9", async function() {        
        var bal_before = web3.eth.getBalance(owner);            
        var gasPrice = 1 //in gwei
        var tx = await manager.withdrawEth({from: owner});                
        const txfee = web3.toWei(tx.receipt.cumulativeGasUsed * gasPrice, 'gwei');

        var bal_after = web3.eth.getBalance(owner);
        var bal_cont = web3.eth.getBalance(manager.address);
        /*var sum = bal_before.plus(txfee).plus(web3.toWei(10, 'ether')).toString();
        assert.equal(bal_after.toString(), sum, 'owner balance is not increas on ' + (web3.toWei(10, 'ether') - txfee).toString());*/
        assert.isTrue(bal_after.minus(bal_before) > web3.toWei(9.9, 'ether'), 'account #9 balance not increased on 9.9 ether');
        assert.equal(bal_cont.toString(), 0, 'contract balance is not empty');
    });

    it("withdrawEth: try call from other account, catch exception, balance not changed", async function() {
        var not_owner = accounts[1];
        var error = null;
        var bal_before = web3.eth.getBalance(not_owner);

        try {
            await manager.withdrawEth({from: not_owner});
        } catch(err) {
            error = err.message;
        }

        var bal_after = web3.eth.getBalance(not_owner);
        var bal_cont = web3.eth.getBalance(manager.address);
        assert.notEqual(error, null, 'Error must be returned');
        assert.isTrue(bal_after < bal_before, 'account #1 balance increased');
        assert.equal(bal_cont.toString(), web3.toWei(10, 'ether'), 'contract balance is changed');
    });
    
    it("owned: get default owner, account #9 is owner ", async function(){
        assert.equal(await manager.owner(), owner, 'account #9 is not owner');
    });

    it("owned: owner call changeOwner, account #1 is newOwner", async function(){
        var new_owner = accounts[1];            
        
        await manager.changeOwner(new_owner, { from: owner });
        var newOwner = await manager.newOwner();
        assert.equal(newOwner, new_owner, 'new owner is not account #1');            
    });

    it("owned: owner call confirmOwner, account #1 is owner", async function(){
        var new_owner = accounts[1];  
        await manager.changeOwner(new_owner, { from: owner });

        await manager.confirmOwner({from: new_owner});
        assert.equal(await manager.owner(), new_owner, 'account #1 is not owner');
    });  
    
});