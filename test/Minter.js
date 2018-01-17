var MinterMock = artifacts.require('./mock/MinterMock.sol');
var SmartValleyTokenMock = artifacts.require("./mock/SmartValleyTokenMock.sol");

contract('Minter', async function(accounts) {

    let token;
    let minter;
    let owner;
    let amount = 120 * (10 ** 18);  

    beforeEach(async function() {
        owner = accounts[8];
        token = await SmartValleyTokenMock.new(owner, amount, {from: owner});
        minter = await MinterMock.new(token.address, {from: owner});
        await token.setMinter(minter.address, {from: owner});
    });

    it('getTokens: to get 1200 tokens on account #2, balance increased, account #2 added in reveiversDateMap', async function() {
        let receiver = accounts[2];

        await minter.getTokens({from: receiver});
        const balanceSVT = await token.balanceOf(receiver);

        assert.equal(web3.fromWei(balanceSVT, 'ether'), 1200, 'balance of tokens is not changed');        
        assert.isTrue(new Date().getTime() - (await minter.receiversDateMap(receiver) * 1000) < 2000, '');
        //console.log((await token.totalSupply()).toString());
        //assert.equal(web3.fromWei(await token.totalSupply(), 'ether'), 1200, 'total SVT supply incorrec');        
    });

    it('getTokens: try to get tokens on accaount #2 again, error, balance not changed', async function() {
        let receiver = accounts[2];        
        let error = null;
        await minter.getTokens({from: receiver});

        try {
            await minter.getTokens({from: receiver});
        } catch (e) {
            error = e.message;
        }
        const balanceSVT = await token.balanceOf(receiver);

        assert.notEqual(error, null, 'Error must be returned');
        assert.equal(web3.fromWei(balanceSVT, 'ether'), 1200, 'balance of tokens is not changed');
    });

    it('getTokens: to get tokens again, on 3-thd day, balance increased', async function() {
        let receiver = accounts[2];
        await minter.getTokens({from: receiver});        
        await minter.putToDateMap(receiver, -3);

        await minter.getTokens({from: receiver});

        const balanceSVT = await token.balanceOf(receiver);
        assert.equal(web3.fromWei(balanceSVT, 'ether'), 2400, 'balance of tokens is not changed');
    });

    it('getTokens: to get tokens again, after 3 days', async function() {
        let receiver = accounts[2];
        await minter.getTokens({from: receiver});        
        await minter.putToDateMap(receiver, -4);

        await minter.getTokens({from: receiver});

        const balanceSVT = await token.balanceOf(receiver);
        assert.equal(web3.fromWei(balanceSVT, 'ether'), 2400, 'balance of tokens is not changed');
    });

    it('getTokens: to get tokens again, on 3thd day', async function() {
        let receiver = accounts[2];
        await minter.getTokens({from: receiver});        
        await minter.putToDateMap(receiver, -3);

        await minter.getTokens({from: receiver});

        const balanceSVT = await token.balanceOf(receiver);
        assert.equal(web3.fromWei(balanceSVT, 'ether'), 2400, 'balance of tokens is not changed');
    });

    it('getTokens: try to get tokens again, less then 3 days', async function() {
        let receiver = accounts[2];
        let error = null;
        await minter.getTokens({from: receiver});        
        await minter.putToDateMap(receiver, -2);        

        try {
            await minter.getTokens({from: receiver});
        } catch (e) {
            error = e.message;
        }        

        const balanceSVT = await token.balanceOf(receiver);
        assert.notEqual(error, null, 'Error must be returned');
        assert.equal(web3.fromWei(balanceSVT, 'ether'), 1200, 'balance of tokens is not changed');
    });

    it('canGetTokens: should can get, if not received early', async function() {
        let receiver = accounts[2];
        assert.isTrue(await minter.canGetTokens(receiver), 'account #2 can\'t get tokens...');
    });

    it('canGetTokens: should can get, if received 3 days ago', async function() {
        let receiver = accounts[2];
        await minter.getTokens({from: receiver});        
        await minter.putToDateMap(receiver, -3);

        assert.isTrue(await minter.canGetTokens(receiver), 'account #2 can\'t get tokens...');
    });

    it('canGetTokens: should can get, if received more then 3 days ago', async function() {
        let receiver = accounts[2];
        await minter.getTokens({from: receiver});        
        await minter.putToDateMap(receiver, -4);
        
        assert.isTrue(await minter.canGetTokens(receiver), 'account #2 can\'t get tokens...');
    });

    it('canGetTokens: should can not get, if received less then 3 days ago', async function() {
        let receiver = accounts[2];        
        await minter.getTokens({from: receiver});        
        await minter.putToDateMap(receiver, -2);                
        
        assert.isNotTrue(await minter.canGetTokens(receiver), 'account #2 can\'t get tokens...');
    });

    it('setAmountToGift: should can set amount to gift', async function() {
        await minter.setAmountToGift(300, {from: owner});
        assert.equal(await minter.amountToGift(), 300, 'amountToGift not equal 300 tokens');
    });

    it('setAmountToGift: should set amount only owner', async function() {
        let error = null;        

        try {
            await minter.setAmountToGift(300);
        } catch (e) {
            error = e.message;
        }                
        
        assert.notEqual(error, null, 'Error must be returned');        
        assert.equal(await minter.amountToGift(), 1200, 'amountToGift was changed');
    });

    [-100.123456789012345678, -100, 0, 0.000006789012345678, 100, 100.123456789012345678].forEach(async (v, idx, arr) => {
        await setAmountToGiftTest(v);
    });

    async function setAmountToGiftTest(value) {

        it('setAmountToGift: should can set only positiv value -> ' + value, async function() {
            let error = null;        

            if(value > 0) {
                
                await minter.setAmountToGift(value, {from: owner});
                assert.equal(await minter.amountToGift(), value, 'amountToGift not equal ' + value + ' tokens');       

            } else {

                try {
                    await minter.setAmountToGift(value, {from: owner});                   
                } catch (e) {
                    error = e.message;                  
                }        
                
                assert.notEqual(error, null, 'Error must be returned');
                assert.equal(await minter.amountToGift(), 1200, 'amountToGift not changed');
            }            
        });
    }

    it('setTokenAddress: should can set new token address', async function() {                
        let new_token = await SmartValleyTokenMock.new(owner, amount, {from: owner});

        await minter.setTokenAddress(new_token.address, {from: owner});

        assert.equal(await minter.token(), new_token_address, 'new token address is not setted');
    });

    it('setAmountToGift: should can set new token only owner', async function() {
        let new_token = await SmartValleyTokenMock.new(owner, amount, {from: owner});
        let error = null;        

        try {
            await minter.setTokenAddress(new_token.address);
        } catch (e) {
            error = e.message;
        }        
        
        assert.notEqual(error, null, 'Error must be returned');
        assert.equal(await minter.token(), token.address, 'old token address was changed');
    });

    it('get DAYS_INTERVAL_BETWEEN_RECEIVE value', async function() {
        assert.equal(await minter.DAYS_INTERVAL_BETWEEN_RECEIVE(), 3, 'invalid days count');
    });
});