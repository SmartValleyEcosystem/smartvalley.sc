var AdministratorsRegistryMock = artifacts.require('./mock/AdministratorsRegistryMock.sol');
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

        administratorsRegistry = await AdministratorsRegistryMock.new({from: owner});
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

        await token.setMinter(owner, {from: owner});

        await token.mint(participant1, 1000, {from: owner});
        await token.mint(participant2, 1000, {from: owner});

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

        await token.freeze(amount * 2, event.address, {from: participant1});
        assert.equal(await event.participantBids(participant1), amount * 3, 'frozen amount of tokens should be added to the previously registered amount');

        var results = await event.getResults();
        var totalTokens = +results[0];
        var totalBids = +results[1];
        var participants = results[2];
        var participantAmounts = results[3];
        var participantShares = results[4];

        assert.equal(totalTokens, totalShitcoinsToDistribute, 'total shitcoins amount should be correct');
        assert.equal(totalBids, amount * 4, 'total bids amount should be correct');

        assert.equal(participants.length, 2, '2 participants should be registered');
        assert.equal(participants[0], participant1, 'first participant should be registered');
        assert.equal(participants[1], participant2, 'second participant should be registered');

        assert.equal(participantAmounts.length, 2, '2 participant amounts should be returned');
        assert.equal(+participantAmounts[0], amount * 3, 'first participant amount should be correct');
        assert.equal(+participantAmounts[1], amount, 'second participant amount should be correct');

        assert.equal(participantShares.length, 2, '2 participant shares should be returned');
        var firstShare = +participantShares[0];
        assert.equal(firstShare, totalShitcoinsToDistribute * 3 / 4, 'first participant share should be correct');
        var secondShare = +participantShares[1];
        assert.equal(secondShare, totalShitcoinsToDistribute * 1 / 4, 'second participant share should be correct');
        assert.equal(firstShare + secondShare, totalShitcoinsToDistribute, 'sum of participant shares should equal to total shitcoins amount');

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