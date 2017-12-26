var SmartValleyTokenMigrator = artifacts.require("./SmartValleyTokenMigrator.sol");
var SmartValleyTokenMock = artifacts.require("./mock/SmartValleyTokenMock.sol");
var KnownContractMock = artifacts.require("./mock/KnownContractMock.sol");

contract('SmartValleyToken', function(accounts) {

    let token;
    let owner;
    let amount = 100;

    beforeEach(async function(){
        owner = accounts[9];
        token = await SmartValleyTokenMock.new(owner, amount, {from: owner});
    });

    it("Should mint tokens", async function() {
        await token.setMinter(accounts[1], {from: owner});
        await token.mintTokens(accounts[0], amount, {from: accounts[1]});
        
        let balance = await token.balanceOf(accounts[0]);
        let totalSupply = await token.totalSupply();
        
        assert.equal(balance, amount, 'Balance should be equal to 1 ether, actual: ' + balance);
        assert.equal(totalSupply, amount*2, 'TotalSupply should be equal to 1 ether, actual: ' + totalSupply);
    });
    
    it("Should require positive amount when mint tokens", async function() {
        await token.setMinter(accounts[1], {from: owner});
        
        let error = null;
        try {
            await token.mintTokens(accounts[0], 0, {from: accounts[1]});
        } catch (e){
            error = e;
        }

        let balance = await token.balanceOf(accounts[0]);
        assert.notEqual(error, null, 'Error should be thrown.');
        assert.equal(balance, 0, 'Balance should be equal to 0 ether, actual: ' + balance);
    });
    
    it("Set minter should be available only for owner", async function() {
        
        let error = null;
        try {
            await token.setMinter(accounts[0], {from: accounts[1]});
        } catch (e){
            error = e;
        }

        assert.notEqual(error, null, 'Error should be thrown.');
    });
    
    it("Mint tokens should be available only to allowed address", async function() {
        
        await token.setMinter(accounts[1], {from: owner});
        
        let error = null;
        try {
            await token.mintTokens(accounts[0], amount, {from: accounts[2]});
        } catch (e){
            error = e;
        }

        let balance = await token.balanceOf(accounts[0]);
        assert.notEqual(error, null, 'Error should be thrown.');
        assert.equal(balance, 0, 'Balance should be equal to 0 ether, actual: ' + balance);
    });
    
    it("Should set minter", async function() {
        await token.setMinter(accounts[1], {from: owner});
        
        let minter = await token.minter();

        assert.equal(minter, accounts[1], 'Invalid minter address.');
    });
    
    it("Should set burner", async function() {
        await token.setBurner(accounts[1], {from: owner});
        
        let burner = await token.burner();

        assert.equal(burner, accounts[1], 'Invalid burner address.');
    });
    
    it("Should burn tokens", async function() {
        
        await token.setBurner(accounts[3], {from: owner});
        
        await token.burnTokens(owner, amount, {from: accounts[3]});
        
        let balance = await token.balanceOf(owner);
        let totalSupply = await token.totalSupply();
        
        assert.equal(balance, 0, 'Balance should be equal to 1 ether, actual: ' + balance);
        assert.equal(totalSupply, 0, 'TotalSupply should be equal to 1 ether, actual: ' + totalSupply);
    });
    
    it("Set burner should be available only for owner", async function() {
        
        let error = null;
        try {
            await token.setBurner(accounts[0], {from: accounts[1]});
        } catch (e){
            error = e;
        }

        assert.notEqual(error, null, 'Error should be thrown.');
    });
    
    it("Burn tokens should be available only to allowed address", async function() {
        
        await token.setBurner(accounts[3], {from: owner});
        
        let error = null;
        try {
            await token.burnTokens(owner, amount, {from: accounts[2]});
        } catch (e){
            error = e;
        }

        let balance = await token.balanceOf(owner);
        assert.notEqual(error, null, 'Error should be thrown.');
        assert.equal(balance, amount, 'Balance should be equal to 0 ether, actual: ' + balance);
    });
    
    it("Burn tokens should only burn available amount", async function() {
        
        await token.setBurner(accounts[3], {from: owner});
        
        let error = null;
        try {
            await token.burnTokens(owner, amount*2, {from: accounts[3]});
        } catch (e){
            error = e;
        }

        let balance = await token.balanceOf(owner);
        assert.notEqual(error, null, 'Error should be thrown.');
        assert.equal(balance, amount, 'Balance should be equal to 0 ether, actual: ' + balance);
    });

    it("Should migrate from previous contract", async function() {
        
        let migrator = await SmartValleyTokenMigrator.new();
        
        await token.setMinter(migrator.address, {from: owner});
        await migrator.migrate(accounts[0], token.address, amount);
        
        let balance = await token.balanceOf(accounts[0]);
        let totalSupply = await token.totalSupply();
        
        assert.equal(balance, amount, 'Balance should be equal to 1 ether, actual: ' + balance);
        assert.equal(totalSupply, amount*2, 'TotalSupply should be equal to 1 ether, actual: ' + totalSupply);
    });
    
    it("Should migrate from previous contract only once", async function() {
        
        let migrator = await SmartValleyTokenMigrator.new();
        
        await token.setMinter(migrator.address, {from: owner});
        await migrator.migrate(accounts[0], token.address, amount);
        
        let error = null;
        try {
            await migrator.migrate(accounts[0], token.address, amount);
        } catch (e){
            error = e;
        }
        
        let balance = await token.balanceOf(accounts[0]);
        let totalSupply = await token.totalSupply();

        assert.notEqual(error, null, 'Error should be thrown.');
        assert.equal(balance, amount, 'Balance should be equal to 1 ether, actual: ' + balance);
        assert.equal(totalSupply, amount*2, 'TotalSupply should be equal to 1 ether, actual: ' + totalSupply);
    });

    // TODO isTransferAllowed is temporarily set to 'true'

    // it("Should block transfer while minting allowed", async function() {
        
    //     let initialBalance = 255;
    //     let tokenMock = await SmartValleyTokenMock.new(accounts[0], initialBalance);

    //     let error = null;
    //     try {
    //         await tokenMock.transfer(accounts[1], 100);
    //     } catch (e){
    //         error = e;
    //     }
        
    //     let firstBalance = await tokenMock.balanceOf(accounts[0]);
    //     let secondBalance = await tokenMock.balanceOf(accounts[1]);

    //     assert.equal(firstBalance, initialBalance, 'Balance should be equal to ' + initialBalance +', actual: ' + firstBalance);
    //     assert.equal(secondBalance, 0, 'Balance should be equal to 0, actual: ' + secondBalance);
    //     assert.notEqual(error, null, 'Error should be thrown.');
    // });
    
    it("Should allow transfer when minting blocked", async function() {
        
        let initialBalance = 255;
        let tokenMock = await SmartValleyTokenMock.new(accounts[0], initialBalance);

        await tokenMock.blockMinting();
        await tokenMock.transfer(accounts[1], 100);
        
        let firstBalance = await tokenMock.balanceOf(accounts[0]);
        let secondBalance = await tokenMock.balanceOf(accounts[1]);

        assert.equal(firstBalance, 155, 'Balance should be equal to 155, actual: ' + firstBalance);
        assert.equal(secondBalance, 100, 'Balance should be equal to 100, actual: ' + secondBalance);
    });
    
    it("Block minting should be allowed only for owner", async function() {
        
        let error = null;
        try {
            await token.blockMinting({from: accounts[1]});
        } catch (e){
            error = e;
        }

        assert.notEqual(error, null, 'Error should be thrown.');
    });
    
    it("Block minting should block setMinter function", async function() {
        
        await token.blockMinting({from: owner});
        
        let error = null;
        try {
            await token.setMinter(accounts[0], {from: owner});
        } catch (e){
            error = e;
        }

        assert.notEqual(error, null, 'Error should be thrown.');
    });
    
    it("addKnownContract should add contract to known list", async function() {
        
        await token.addKnownContract(accounts[0], {from: owner});
        
        let result = await token.knownContracts(accounts[0]);

        assert.equal(result, true, 'Known contract isn`t saved.');
    });
    
    it("removeKnownContract should remove contract from known list", async function() {
        
        await token.addKnownContract(accounts[0], {from: owner});
        await token.removeKnownContract(accounts[0], {from: owner});
        
        let result = await token.knownContracts(accounts[0]);

        assert.equal(result, false, 'Known contract isn`t saved.');
    });
    
    it("addKnownContract should be available only for owner", async function() {
        
        let error = null;
        try {
            await token.addKnownContract(accounts[0]);
        } catch (e){
            error = e;
        }

        let result = await token.knownContracts(accounts[0]);

        assert.equal(result, false, 'Known contract isn`t saved.');
        assert.notEqual(error, null, 'Error should be thrown.');
    });
    
    it("removeKnownContract should be available only for owner", async function() {
        await token.addKnownContract(accounts[0], {from: owner});
        
        let error = null;
        try {
            await token.removeKnownContract(accounts[0]);
        } catch (e){
            error = e;
        }

        let result = await token.knownContracts(accounts[0]);

        assert.equal(result, true, 'Known contract isn`t saved.');
        assert.notEqual(error, null, 'Error should be thrown.');
    });
    
    it("transferToKnownContract should be available only for knownContracts", async function() {
        let knownContract = await KnownContractMock.new();

        await token.blockMinting({from: owner});
        
        let error = null;
        try {
            await token.transferToKnownContract(knownContract.address, amount, [], {from: owner});
        } catch (e){
            error = e;
        }
        
        let transferedValue = await knownContract.transferedValue();
        let callCount = await knownContract.callCount();
        assert.equal(transferedValue, 0, 'Invalid transfered value: ' + transferedValue);
        assert.equal(callCount, 0, 'Invalid call count: ' + callCount);
        assert.notEqual(error, null, 'Error should be thrown.');
    });

    // TODO isTransferAllowed is temporarily set to 'true'

    // it("transferToKnownContract should be available only when minter blocked", async function() {
    //     let knownContract = await KnownContractMock.new();

    //     await token.addKnownContract(knownContract.address, {from: owner});
        
    //     let error = null;
    //     try {
    //         await token.transferToKnownContract(knownContract.address, amount, [], {from: owner});
    //     } catch (e){
    //         error = e;
    //     }
        
    //     let transferedValue = await knownContract.transferedValue();
    //     let callCount = await knownContract.callCount();
    //     assert.equal(transferedValue, 0, 'Invalid transfered value: ' + transferedValue);
    //     assert.equal(callCount, 0, 'Invalid call count: ' + callCount);
    //     assert.notEqual(error, null, 'Error should be thrown.');
    // });

    it("transferToKnownContract should transfer tokens", async function() {
        
        let knownContract = await KnownContractMock.new();

        await token.blockMinting({from: owner});
        await token.addKnownContract(knownContract.address, {from: owner});
        await token.transferToKnownContract(knownContract.address, amount, [], {from: owner});
        
        let balance = await token.balanceOf(knownContract.address);
        let transferedValue = await knownContract.transferedValue();
        let callCount = await knownContract.callCount();
        assert.equal(transferedValue, amount, 'Invalid transfered value: ' + transferedValue);
        assert.equal(callCount, 1, 'Invalid call count: ' + callCount);
        assert.equal(balance, amount, 'Invalid balance: ' + balance);
    });
    
    it("transfer should call transfered in known contract", async function() {
        
        let knownContract = await KnownContractMock.new();

        await token.blockMinting({from: owner});
        await token.addKnownContract(knownContract.address, {from: owner});
        await token.transfer(knownContract.address, amount, {from: owner});
        
        let balance = await token.balanceOf(knownContract.address);
        let transferedValue = await knownContract.transferedValue();
        let callCount = await knownContract.callCount();
        assert.equal(transferedValue, amount, 'Invalid transfered value: ' + transferedValue);
        assert.equal(callCount, 1, 'Invalid call count: ' + callCount);
        assert.equal(balance, amount, 'Invalid balance: ' + balance);
    });  
});