var ScoringManagerMock = artifacts.require('./mock/ScoringManagerMock.sol');
var PrivateScoringManager = artifacts.require('./PrivateScoringManager.sol');
var PrivateScoring = artifacts.require('./PrivateScoring.sol');
var ScoringMock = artifacts.require('./mock/ScoringMock.sol');
var AdministratorsRegistryMock = artifacts.require('./mock/AdministratorsRegistryMock.sol');
var ExpertsRegistryMock = artifacts.require('./mock/ExpertsRegistryMock.sol');
var ScoringsRegistry = artifacts.require('./ScoringsRegistry.sol');
var ScoringParametersProvider = artifacts.require('./ScoringParametersProvider.sol');
var ScoringOffersManagerMock = artifacts.require('./mock/ScoringOffersManagerMock.sol');
var RandomGenerator = artifacts.require('./RandomGenerator.sol');
var ArrayExtensions = artifacts.require('./ArrayExtensions.sol');

contract('ScoringManager', async function(accounts) {

    var hrAreaId = 1;
    var hrAreaMaxScore = 16;
    var hrCriterionIds =     [14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24];
    var hrCriterionWeights = [10, 10,  3,  4,  7,  3,  6,  5,  5,  2,  3];
  
    var analystAreaId = 2;
    var analystAreaMaxScore = 23;
    var analystCriterionIds =     [29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48];
    var analystCriterionWeights = [10, 10,  7,  5,  6,  2,  5,  2,  2,  5,  3, 10, 10,  7,  5,  3,  8,  5,  3,  5];
  
    var techAreaId = 3;
    var techAreaMaxScore = 17;
    var techCriterionIds =     [25, 26, 27, 28];
    var techCriterionWeights = [ 5, 3, 10,  5];
  
    var lawyerAreaId = 4;
    var lawyerAreaMaxScore = 27;
    var lawyerCriterionIds =     [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
    var lawyerCriterionWeights = [10, 3, 1, 4, 4, 2, 8, 4, 8,  4,  7,  3,  3];
  
    var marketerAreaId = 5;
    var marketerAreaMaxScore = 17;
    var marketerCriterionIds =     [49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68];
    var marketerCriterionWeights = [ 3,  7,  9,  9, 10,  6, 10,  9,  6,  4,  4,  4,  4,  6,  4,  6,  8,  3,  5,  7];
  
    let scoringManager;
    let privateScoringManager;
    let owner;
    let administratorsRegistry;
    let expertsRegistry;
    let scoringsRegistry;
    let randomGenerator;
    let arrayExtensions;
    let scoringOffersManager;
    let scoringParametersProvider;

    let areas = [1, 2, 3, 4, 5];

    async function addExperts(areaExpertsCount) {
        const chunkSize = 15;
        for (let k = 0; k < areaExpertsCount / chunkSize; k++) {
            const expertList = [];
            const currentChunkSize = (k + 1) * chunkSize < areaExpertsCount ? chunkSize : areaExpertsCount % (k * chunkSize);

            for (let i = 0; i < currentChunkSize; i++) {
                expertList.push(await web3.personal.newAccount());
            }
            await expertsRegistry.addExperts(expertList, areas, {from: owner});
        }
    }

    async function initializeCriteria() {
        const reward = +web3.toWei(0.1, 'ether').toString();

        await scoringParametersProvider.initializeAreaParameters(
            hrAreaId,
            hrAreaMaxScore,
            reward,
            hrCriterionIds,
            hrCriterionWeights,
            {from: owner});

        await scoringParametersProvider.initializeAreaParameters(
            analystAreaId,
            analystAreaMaxScore,
            reward,
            analystCriterionIds,
            analystCriterionWeights,
            {from: owner});

        await scoringParametersProvider.initializeAreaParameters(
            techAreaId,
            techAreaMaxScore,
            reward,
            techCriterionIds,
            techCriterionWeights,
            {from: owner});

        await scoringParametersProvider.initializeAreaParameters(
            lawyerAreaId,
            lawyerAreaMaxScore,
            reward,
            lawyerCriterionIds,
            lawyerCriterionWeights,
            {from: owner});

        await scoringParametersProvider.initializeAreaParameters(
            marketerAreaId,
            marketerAreaMaxScore,
            reward,
            marketerCriterionIds,
            marketerCriterionWeights,
            {from: owner});
    }

    beforeEach(async function(){
        owner = accounts[8];

        administratorsRegistry = await AdministratorsRegistryMock.new({from: owner});
        scoringParametersProvider = await ScoringParametersProvider.new(administratorsRegistry.address, {from: owner});
        expertsRegistry = await ExpertsRegistryMock.new(administratorsRegistry.address, scoringParametersProvider.address, {from: owner});
        randomGenerator = await RandomGenerator.new({from: owner});
        arrayExtensions = await ArrayExtensions.new({from: owner});
        scoringsRegistry = await ScoringsRegistry.new({from: owner});
        scoringOffersManager = await ScoringOffersManagerMock.new(3, 2, 2, expertsRegistry.address, administratorsRegistry.address, scoringsRegistry.address, {from: owner});

        scoringManager = await ScoringManagerMock.new(scoringOffersManager.address, administratorsRegistry.address, scoringsRegistry.address, scoringParametersProvider.address, {from: owner});
        privateScoringManager = await PrivateScoringManager.new(scoringOffersManager.address, administratorsRegistry.address, scoringsRegistry.address, scoringParametersProvider.address, {from: owner});

        await scoringsRegistry.setScoringManager(scoringManager.address, {from: owner});
        await scoringsRegistry.setPrivateScoringManager(privateScoringManager.address, {from: owner});
        await scoringsRegistry.setScoringOffersManager(scoringOffersManager.address, {from: owner});

        await administratorsRegistry.add(owner, {from: owner});

        console.log('INITIALIZING CRITERIA...');
        await initializeCriteria();

        console.log('ADDING EXPERTS...');
        await addExperts(50);

        await scoringOffersManager.setScoringManager(scoringManager.address, {from: owner});
        await scoringOffersManager.setPrivateScoringManager(privateScoringManager.address, {from: owner});
    });

    it.only('expert should send estimates by area to scoring', async function() {
        const projectId = Math.floor(Math.random() * (100000000 - 1000000 + 1)) + 1000000;

        console.log('STARTING SCORING...');

        var areaExpertCounts = [10, 10, 10, 10, 10];
        var startTransaction = await scoringManager.start(projectId, areas, areaExpertCounts, {from: owner, value: web3.toWei(5, 'ether')});

        console.log(`GAS USED: ${startTransaction.receipt.gasUsed}`);

        let offers = await scoringOffersManager.get(projectId);
        assert.equal(offers[0].length, 150, 'there should be 150 offers');

        console.log(`ACCEPTING OFFER...`);

        await web3.eth.sendTransaction({from: accounts[0], to: offers[1][0], value: web3.toWei(2, "ether")});
        await web3.personal.unlockAccount(offers[1][0]);

        var acceptTransaction = await scoringOffersManager.accept(projectId, offers[0][0], {from: offers[1][0]});
        console.log(`GAS USED: ${acceptTransaction.receipt.gasUsed}`);

        console.log(`REJECTING OFFER...`);
        await web3.eth.sendTransaction({from: accounts[0], to: offers[1][1], value: web3.toWei(2, "ether")});
        await web3.personal.unlockAccount(offers[1][1]);

        var rejectTransaction = await scoringOffersManager.reject(projectId, offers[0][1], {from: offers[1][1]});
        console.log(`GAS USED: ${rejectTransaction.receipt.gasUsed}`);

        offers = await scoringOffersManager.get(projectId);

        assert.equal(+offers[2][0].toString(), 1, 'first offer should be accepted');
        assert.equal(+offers[2][1].toString(), 2, 'second offer should be rejected');
    });

    it('expert should send estimates by area to private scoring', async function() {
        const projectId = Math.floor(Math.random() * (100000000 - 1000000 + 1)) + 1000000;

        console.log('STARTING PRIVATE SCORING...');

        var hrExperts = await expertsRegistry.getExpertsInArea(hrAreaId);
        var analystExperts = await expertsRegistry.getExpertsInArea(analystAreaId);
        var techExperts = await expertsRegistry.getExpertsInArea(techAreaId);
        var lawyerExperts = await expertsRegistry.getExpertsInArea(lawyerAreaId);

        let expertAreas = [hrAreaId,     hrAreaId,     analystAreaId,     techAreaId];
        let experts =     [hrExperts[0], hrExperts[1], analystExperts[0], techExperts[4]];

        var startTransaction = await privateScoringManager.start(projectId, expertAreas, experts, {from: owner});
        console.log(`GAS USED: ${startTransaction.receipt.gasUsed}`);

        let hrExpertsCount = await scoringsRegistry.getRequiredExpertsCount(projectId, hrAreaId);
        assert.equal(+hrExpertsCount.toString(), 2, 'required HR experts count should be 2');

        let analystExpertsCount = await scoringsRegistry.getRequiredExpertsCount(projectId, analystAreaId);
        assert.equal(+analystExpertsCount.toString(), 1, 'required analyst experts count should be 1');

        let techExpertsCount = await scoringsRegistry.getRequiredExpertsCount(projectId, techAreaId);
        assert.equal(+techExpertsCount.toString(), 1, 'required tech experts count should be 1');

        let lawyerExpertsCount = await scoringsRegistry.getRequiredExpertsCount(projectId, lawyerAreaId);
        assert.equal(+lawyerExpertsCount.toString(), 0, 'required lawyer experts count should be 0');

        console.log('SUBMITTING ESTIMATES...');

        var conclusionHash = web3.sha3("conclusion");
        var scores = [2, 2, 2, 2];
        var comments = [web3.sha3("comment"), web3.sha3("comment"), web3.sha3("comment"), web3.sha3("comment")];

        await web3.eth.sendTransaction({from: accounts[0], to: techExperts[4], value: web3.toWei(2, "ether")});
        await web3.personal.unlockAccount(techExperts[4]);

        var estimatesTransaction = await privateScoringManager.submitEstimates(projectId, techAreaId, conclusionHash, techCriterionIds, scores, comments, {from: techExperts[4]});
        console.log(`GAS USED: ${estimatesTransaction.receipt.gasUsed}`);

        var scoringAddress = await scoringsRegistry.getScoringAddressById(projectId);
        var scoring = PrivateScoring.at(scoringAddress);

        let results = await scoring.getResults();
        let score = +results[0].toString();
        let techScore = +results[2][2].toString();

        assert.equal(techScore / 100, techAreaMaxScore, 'tech score should be max');
        assert.equal(score / 100, techAreaMaxScore, 'total score should be equal to tech max score');

        let estimates = await scoring.getEstimates();
        assert.equal(estimates[0].length, techCriterionIds.length, 'four estimates should be submitted');

        console.log('SETTING EXPERTS...');

        let newExpertAreas = [hrAreaId,     analystAreaId,     lawyerAreaId,     lawyerAreaId];
        let newExperts =     [hrExperts[0], analystExperts[0], lawyerExperts[2], lawyerExperts[3]];

        var setExpertsTransaction = await scoringOffersManager.set(projectId, newExpertAreas, newExperts, {from: owner});
        console.log(`GAS USED: ${setExpertsTransaction.receipt.gasUsed}`);

        results = await scoring.getResults();
        score = +results[0].toString();
        techScore = +results[2][2].toString();

        assert.equal(techScore, 0, 'tech score zero');
        assert.equal(score, 0, 'total score should be zero');

        estimates = await scoring.getEstimates();
        assert.equal(estimates[0].length, 0, 'zero estimates should be submitted');

        let offers = await scoringOffersManager.get(projectId);
        assert.equal(offers[0].length, 4, 'there should be four offers');

        var hrOffers = await scoringsRegistry.getOffers(projectId, hrAreaId);
        assert.equal(hrOffers.length, 1, 'there should be one HR offer');

        var analystOffers = await scoringsRegistry.getOffers(projectId, analystAreaId);
        assert.equal(analystOffers.length, 1, 'there should be one analyst offer');

        var techOffers = await scoringsRegistry.getOffers(projectId, techAreaId);
        assert.equal(techOffers.length, 0, 'there should be no tech offers');

        var lawyerOffers = await scoringsRegistry.getOffers(projectId, lawyerAreaId);
        assert.equal(lawyerOffers.length, 2, 'there should be two lawyer offers');

        hrExpertsCount = await scoringsRegistry.getRequiredExpertsCount(projectId, hrAreaId);
        assert.equal(+hrExpertsCount.toString(), 1, 'required HR experts count should be 1');

        analystExpertsCount = await scoringsRegistry.getRequiredExpertsCount(projectId, analystAreaId);
        assert.equal(+analystExpertsCount.toString(), 1, 'required analyst experts count should be 1');

        techExpertsCount = await scoringsRegistry.getRequiredExpertsCount(projectId, techAreaId);
        assert.equal(+techExpertsCount.toString(), 0, 'required tech experts count should be 0');

        lawyerExpertsCount = await scoringsRegistry.getRequiredExpertsCount(projectId, lawyerAreaId);
        assert.equal(+lawyerExpertsCount.toString(), 2, 'required lawyer experts count should be 2');
    })
});