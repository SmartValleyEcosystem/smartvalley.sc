var AdministratorsRegistry = artifacts.require('./AdministratorsRegistry.sol');
var SafeMath = artifacts.require('./SafeMath.sol');
var ContractExtensions = artifacts.require('./ContractExtensions.sol');
var AllotmentEventsManager = artifacts.require('./AllotmentEventsManager.sol');
var AllotmentEvent = artifacts.require('./AllotmentEvent.sol');
var SmartValleyToken = artifacts.require('./SmartValleyToken.sol');

contract('AllotmentEvent', async function(accounts) {

    var daySeconds = 86400;
    var eventDuration = 5;
    var freezingDuration = 7;
    var eventId = 123;
    var totalShitcoinsToDistribute = 1000000;
    var owner;
    var admin;

    var participant1;
    var participant2;

    var eventsManager;
    var administratorsRegistry;
    var token;
    var shitToken;
    var event;

    beforeEach(async function(){
        owner = accounts[9];
        admin = accounts[8];

        participant1 = accounts[7];
        participant2 = accounts[6];

        administratorsRegistry = await AdministratorsRegistry.new({from: owner});
        await administratorsRegistry.add(admin, {from: owner});

        await SafeMath.new({from: owner});
        await SmartValleyToken.link(SafeMath, {from: owner});
        await AllotmentEvent.link(SafeMath, {from: owner});

        await ContractExtensions.new({from: owner});
        await SmartValleyToken.link(ContractExtensions, {from: owner});
        await AllotmentEvent.link(ContractExtensions, {from: owner});

        token = await SmartValleyToken.new({from: owner});
        shitToken = await SmartValleyToken.new({from: owner});

        eventsManager = await AllotmentEventsManager.new(administratorsRegistry.address, freezingDuration, token.address, {from: owner});
        await eventsManager.setReturnAddress(accounts[0], {from: admin});

        await token.setMinter(owner, {from: owner});

        await token.mint(participant1, 1000, {from: owner});
        await token.mint(participant2, 1000, {from: owner});
        await token.mint(accounts[1], 1000, {from: owner});
        await token.mint(accounts[2], 1000, {from: owner});
        await token.mint(accounts[3], 1000, {from: owner});
        await token.mint(accounts[4], 1000, {from: owner});
        await token.mint(accounts[5], 1000, {from: owner});
        await token.mint(accounts[8], 1000, {from: owner});

        await token.blockMinting({from: owner});

        var now = Math.floor((new Date()).valueOf() / 1000);
        var finishTimestamp = now + (eventDuration * daySeconds);

        await eventsManager.create(eventId, "name", 18, "SHT", shitToken.address, finishTimestamp, {from: admin});

        var eventAddress = await eventsManager.getAllotmentEventContractAddress(eventId);
        event = AllotmentEvent.at(eventAddress);

        await shitToken.setMinter(owner, {from: owner});
        await shitToken.mint(event.address, totalShitcoinsToDistribute, {from: owner});
        await shitToken.blockMinting({from: owner});

        await eventsManager.start(eventId, {from: admin});
    });

    it.only('token owner should be able to take part in an allotment event', async function () {
        var amount = 50;
        await token.freeze(amount, event.address, {from: participant1});
        assert.equal(await event.participantBids(participant1), amount, 'frozen amount of tokens should be registered in the allotment event contract');

        await token.freeze(amount, event.address, {from: participant2});
        assert.equal(await event.participantBids(participant2), amount, 'frozen amount of tokens should be registered in the allotment event contract');

        await token.freeze(amount, event.address, {from: participant1});
        assert.equal(await event.participantBids(participant1), amount * 2, 'frozen amount of tokens should be added to the previously registered amount');

        await token.freeze(amount, event.address, {from: accounts[1]});
        await token.freeze(amount, event.address, {from: accounts[2]});
        await token.freeze(amount, event.address, {from: accounts[3]});
        await token.freeze(amount, event.address, {from: accounts[4]});
        await token.freeze(amount, event.address, {from: accounts[5]});
        await token.freeze(amount, event.address, {from: accounts[8]});

        var results = await event.getResults();
        var totalTokens = +results[0];
        var totalBids = +results[1];
        var participants = results[2];
        var participantAmounts = results[3];
        var participantShares = results[4];

        assert.equal(totalTokens, totalShitcoinsToDistribute, 'total shitcoins amount should be correct');
        assert.equal(totalBids, amount * 9, 'total bids amount should be correct');

        assert.equal(participants.length, 8, '8 participants should be registered');
        assert.equal(participants[0], participant1, 'first participant should be registered');
        assert.equal(participants[1], participant2, 'second participant should be registered');

        assert.equal(participantAmounts.length, 8, '8 participant amounts should be returned');
        assert.equal(+participantAmounts[0], amount * 2, 'first participant amount should be correct');
        assert.equal(+participantAmounts[1], amount, 'second participant amount should be correct');

        assert.equal(participantShares.length, 8, '8 participant shares should be returned');
        var firstShare = +participantShares[0];
        assert.equal(firstShare, Math.floor(totalShitcoinsToDistribute * 2 / 9), 'first participant share should be correct');
        var secondShare = +participantShares[1];
        assert.equal(secondShare, Math.floor(totalShitcoinsToDistribute * 1 / 9), 'second participant share should be correct');

        assert.equal(await token.getFrozenAmount(participant1), 100, 'correct amount of tokens should be frozen for the first participant');
        assert.equal(await token.getFrozenAmount(participant2), 50, 'correct amount of tokens should be frozen for the second participant');

        try {
            await eventsManager.remove(eventId, {from: owner});
        } catch (error) {
            assert.notEqual(error, null, 'administrator should not be able to remove event with bids');
        }

        do {
            await eventsManager.returnBids(eventId, {from: owner, gas: 300000});
        } while (await event.hasBids());

        await eventsManager.remove(eventId, {from: owner});

        assert.equal(await token.getFrozenAmount(participant1), 0, 'no tokens should be frozen for the first participant');
        assert.equal(await token.getFrozenAmount(participant2), 0, 'no tokens should be frozen for the second participant');

        var returnAddressBalance = await shitToken.balanceOf(accounts[0]);
        assert.equal(returnAddressBalance, 1000000, 'all tokens should be transfered to the return address');

        // await increaseTime(eventDuration + 1);

        // await event.collectTokens({from: participant1});

        // var participant1ShitCoins = await shitToken.balanceOf(participant1);
        // assert.equal(+participant1ShitCoins, totalShitcoinsToDistribute * 3 / 4, 'first participant shit coin balance should be correct');

        // let eventShitCoins = await shitToken.balanceOf(event.address);
        // assert.equal(+eventShitCoins, totalShitcoinsToDistribute * 1 / 4, 'event shit coin balance should be correct');

        // await event.collectTokens({from: participant2});

        // var participant2ShitCoins = await shitToken.balanceOf(participant2);
        // assert.equal(+participant2ShitCoins, totalShitcoinsToDistribute * 1 / 4, 'second participant shit coin balance should be correct');

        // eventShitCoins = await shitToken.balanceOf(event.address);
        // assert.equal(+eventShitCoins, 0, 'there should be no shit coins left on the event contract');
    })

    function increaseTime(days) {
        const id = Date.now();
        return new Promise(
            (resolve, reject) => {
                web3.currentProvider.sendAsync({
                    jsonrpc: '2.0',
                    method: 'evm_increaseTime',
                    params: [days * daySeconds],
                    id: id,
                },
                err1 => {
                    if (err1)
                        return reject(err1);
                    web3.currentProvider.sendAsync({
                        jsonrpc: '2.0',
                        method: 'evm_mine',
                        id: id + 1,
                    },
                    (err2, res) => {
                        return err2 ? reject(err2) : resolve(res)
                    });
                });
            });
    }
});