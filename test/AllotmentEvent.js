var AdministratorsRegistryMock = artifacts.require('./mock/AdministratorsRegistryMock.sol');
var SafeMath = artifacts.require('./SafeMath.sol');
var ContractExtensions = artifacts.require('./ContractExtensions.sol');
var AllotmentEventsManager = artifacts.require('./AllotmentEventsManager.sol');
var AllotmentEvent = artifacts.require('./AllotmentEvent.sol');
var SmartValleyToken = artifacts.require('./SmartValleyToken.sol');

contract('AllotmentEvent', async function(accounts) {

    var freezingDuration = 7;
    var eventId = 123;
    var totalShitcoinsToDistribute = 1000000;
    var owner;
    var admin;

    var tokenHolder1;
    var tokenHolder2;

    var eventsManager;
    var administratorsRegistry;
    var token;
    var shitToken;
    var event;

    beforeEach(async function(){
        owner = accounts[9];
        admin = accounts[8];

        tokenHolder1 = accounts[7];
        tokenHolder2 = accounts[6];

        administratorsRegistry = await AdministratorsRegistryMock.new({from: owner});
        await administratorsRegistry.add(admin, {from: owner});

        await SafeMath.new({from: owner});
        await SmartValleyToken.link(SafeMath, {from: owner});
        await AllotmentEvent.link(SafeMath, {from: owner});

        await ContractExtensions.new({from: owner});
        await SmartValleyToken.link(ContractExtensions, {from: owner});
        await AllotmentEvent.link(ContractExtensions, {from: owner});

        eventsManager = await AllotmentEventsManager.new(administratorsRegistry.address, freezingDuration, {from: owner});

        token = await SmartValleyToken.new({from: owner});
        shitToken = await SmartValleyToken.new({from: owner});

        await token.setMinter(owner, {from: owner});

        await token.mint(tokenHolder1, 1000, {from: owner});
        await token.mint(tokenHolder2, 1000, {from: owner});

        await token.blockMinting({from: owner});

        var eventDuration = 5;
        var now = new Date();
        var then = Math.floor(now.setDate(now.getDate() + eventDuration).valueOf() / 1000);
        await eventsManager.create(eventId, "name", 18, "SHT", shitToken.address, then, {from: admin});

        var eventAddress = await eventsManager.getAllotmentEventContractAddress(eventId);
        event = AllotmentEvent.at(eventAddress);

        await shitToken.setMinter(owner, {from: owner});
        await shitToken.mint(event.address, totalShitcoinsToDistribute, {from: owner});
        await shitToken.blockMinting({from: owner});

        await eventsManager.start(eventId, {from: admin});
    });

    it.only('token owner should be able to take part in an allotment event', async function () {
        var amount = 50;
        await token.freeze(amount, event.address, {from: tokenHolder1});
        assert.equal(await event.participantBids(tokenHolder1), amount, 'frozen amount of tokens should be registered in the allotment event contract');

        await token.freeze(amount, event.address, {from: tokenHolder2});
        assert.equal(await event.participantBids(tokenHolder2), amount, 'frozen amount of tokens should be registered in the allotment event contract');

        await token.freeze(amount * 2, event.address, {from: tokenHolder1});
        assert.equal(await event.participantBids(tokenHolder1), amount * 3, 'frozen amount of tokens should be added to the previously registered amount');

        var results = await event.getResults();
        var totalTokens = +results[0];
        var totalBids = +results[1];
        var participants = results[2];
        var participantAmounts = results[3];
        var participantShares = results[4];

        assert.equal(totalTokens, totalShitcoinsToDistribute, 'total shitcoins amount should be correct');
        assert.equal(totalBids, amount * 4, 'total bids amount should be correct');

        assert.equal(participants.length, 2, '2 participants should be registered');
        assert.equal(participants[0], tokenHolder1, 'first token holder should be registered');
        assert.equal(participants[1], tokenHolder2, 'second token holder should be registered');

        assert.equal(participantAmounts.length, 2, '2 participant amounts should be returned');
        assert.equal(+participantAmounts[0], amount * 3, 'first token holder amount should be correct');
        assert.equal(+participantAmounts[1], amount, 'second token holder amount should be correct');

        assert.equal(participantShares.length, 2, '2 participant shares should be returned');
        var firstShare = +participantShares[0];
        assert.equal(firstShare, totalShitcoinsToDistribute * 3 / 4, 'first token holder share should be correct');
        var secondShare = +participantShares[1];
        assert.equal(secondShare, totalShitcoinsToDistribute * 1 / 4, 'second token holder share should be correct');
        assert.equal(firstShare + secondShare, totalShitcoinsToDistribute, 'sum of token holder shares should equal to total shitcoins amount');
    })
});