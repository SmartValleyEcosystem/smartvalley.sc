var AdministratorsRegistryMock = artifacts.require('./mock/AdministratorsRegistryMock.sol');
var ExpertsRegistryMock = artifacts.require('./mock/ExpertsRegistryMock.sol');
var ScoringParametersProvider = artifacts.require('./ScoringParametersProvider.sol');

contract('ExpertsRegistry', async function(accounts) {

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

    let owner;
    let admin;
    let expert1;
    let expert2;
    let expert3;

    let expertsRegistry;
    let scoringParametersProvider;
    let administratorsRegistry;

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
        owner = accounts[7];
        admin = accounts[6];
        expert1 = accounts[5];
        expert2 = accounts[4];
        expert3 = accounts[3];

        administratorsRegistry = await AdministratorsRegistryMock.new({from: owner});
        await administratorsRegistry.add(admin, {from: owner});

        scoringParametersProvider = await ScoringParametersProvider.new(administratorsRegistry.address, {from: owner});

        let areas = [1, 2, 3, 4, 5];
        expertsRegistry = await ExpertsRegistryMock.new(administratorsRegistry.address, scoringParametersProvider.address, {from: owner});

        console.log('INITIALIZING CRITERIA...');
        await initializeCriteria();
    });

    it('application can be submitted by expert' , async function() {
        var areas = [1, 2];
        await expertsRegistry.apply(areas, web3.sha3("qqq1"), {from: expert1});

        var applications = await expertsRegistry.getApplications({from: owner});
        assert.equal(
            applications[0].length,
            2,
            '2 applications in areas 1 and 2 were not registered');
        assert.equal(
            applications[0][0],
            expert1,
            'first application should be from expert 1');
        assert.equal(
            applications[0][1],
            expert1,
            'second application should be from expert 1');
        assert.equal(
            applications[1][0],
            1,
            'first application should be in area 1');
        assert.equal(
            applications[1][1],
            2,
            'second application should be in area 2');
    });

    it('application can be approved by admin' , async function() {
        var expert2Areas = [1, 2, 3];
        await expertsRegistry.apply(expert2Areas, web3.sha3("qqq1"), {from: expert2});

        var expert1Areas = [1, 2, 3, 4];
        await expertsRegistry.apply(expert1Areas, web3.sha3("qqq1"),  {from: expert1});

        var approvedAreas = [2, 4];
        await expertsRegistry.approve(expert1, approvedAreas, {from: admin});

        var area1ExpertsCount = await expertsRegistry.getExpertsCountInArea(1);
        var area2ExpertsCount = await expertsRegistry.getExpertsCountInArea(2);
        var area3ExpertsCount = await expertsRegistry.getExpertsCountInArea(3);
        var area4ExpertsCount = await expertsRegistry.getExpertsCountInArea(4);

        assert.equal(
            area1ExpertsCount,
            0,
            'there should be no experts in area 1');
        assert.equal(
            area2ExpertsCount,
            1,
            'there should be one expert in area 2');
        assert.equal(
            area3ExpertsCount,
            0,
            'there should be no experts in area 3');
        assert.equal(
            area4ExpertsCount,
            1,
            'there should be one expert in area 4');

        assert.equal(
            await expertsRegistry.expertsByAreaMap(2, 0),
            expert1,
            'expert was not added to area 2 list at proper position');
        assert.equal(
            await expertsRegistry.expertsByAreaMap(4, 0),
            expert1,
            'expert was not added to area 2 list at proper position');

        var applications = await expertsRegistry.getApplications({from: owner});
        assert.equal(
            applications[0].length,
            expert2Areas.length,
            'there are only expert 2 applications left');
    });

    it('application can be rejected by admin' , async function() {
        var expert2Areas = [1, 2, 3];
        await expertsRegistry.apply(expert2Areas, web3.sha3("qqq1"), {from: expert2});

        var expert1Areas = [1, 2, 3, 4];
        await expertsRegistry.apply(expert1Areas, web3.sha3("qqq1"), {from: expert1});

        var approvedAreas = [2, 4];
        await expertsRegistry.reject(expert1, {from: admin});

        var area1ExpertsCount = await expertsRegistry.getExpertsCountInArea(1);
        var area2ExpertsCount = await expertsRegistry.getExpertsCountInArea(2);
        var area3ExpertsCount = await expertsRegistry.getExpertsCountInArea(3);
        var area4ExpertsCount = await expertsRegistry.getExpertsCountInArea(4);

        assert.equal(
            area1ExpertsCount,
            0,
            'there should be no experts in area 1');
        assert.equal(
            area2ExpertsCount,
            0,
            'there should be one expert in area 2');
        assert.equal(
            area3ExpertsCount,
            0,
            'there should be no experts in area 3');
        assert.equal(
            area4ExpertsCount,
            0,
            'there should be one expert in area 4');

        /*assert.equal(
            await expertsRegistry.expertsByAreaMap(2, 0),
            expert1,
            'expert was not added to area 2 list at proper position');
        assert.equal(
            await expertsRegistry.expertsByAreaMap(4, 0),
            expert1,
            'expert was not added to area 2 list at proper position');

        var applications = await expertsRegistry.getApplications({from: owner});
        assert.equal(
            applications[0].length,
            expert2Areas.length,
            'there are only expert 2 applications left');*/
    });

    it('expert can be added by admin' , async function() {
        var areas = [1, 2];
        await expertsRegistry.add(expert1, areas, {from: admin});

        assert.equal(
            await expertsRegistry.expertsByAreaMap(1, 0),
            expert1,
            'expert was not added to area 1 list at proper position');
        assert.equal(
            await expertsRegistry.expertsByAreaMap(2, 0),
            expert1,
            'expert was not added to area 2 list at proper position');
    });

    it('experts in area can be retrieved by indices' , async function() {
        var areas = [1, 2];

        await expertsRegistry.add(expert1, areas, {from: admin});
        await expertsRegistry.add(expert2, areas, {from: admin});
        await expertsRegistry.add(expert3, areas, {from: admin});

        var indices = [1, 2];
        var experts = await expertsRegistry.get(2, indices);

        assert.equal(
            experts[0],
            expert2,
            'expert 2 should be returned as first');
        assert.equal(
            experts[1],
            expert3,
            'expert 3 should be returned as second');
    });

    it('experts can be removed from area' , async function() {
        var areas = [1, 2];

        await expertsRegistry.add(expert1, areas, {from: admin});
        await expertsRegistry.add(expert2, areas, {from: admin});
        await expertsRegistry.add(expert3, areas, {from: admin});

        await expertsRegistry.removeInArea(expert2, 1, {from: admin});
        await expertsRegistry.removeInArea(expert1, 2, {from: admin});

        var area1Experts = await expertsRegistry.get(1, [0, 1]);
        assert.equal(
            area1Experts[0],
            expert1,
            'expert 1 should be returned as first in area 1');
        assert.equal(
            area1Experts[1],
            expert3,
            'expert 3 should be returned as second in area 1');

        var area2Experts = await expertsRegistry.get(2, [0, 1]);
        assert.equal(
            area2Experts[0],
            expert3,
            'expert 3 should be returned as first in area 2');
        assert.equal(
            area2Experts[1],
            expert2,
            'expert 2 should be returned as second in area 2');
    });

    it('experts can be removed' , async function() {
        var areas = [1, 2];
        await expertsRegistry.add(expert1, areas, {from: admin});
        await expertsRegistry.add(expert2, areas, {from: admin});
        await expertsRegistry.add(expert3, areas, {from: admin});

        var area1ExpertsCountBefore = await expertsRegistry.getExpertsCountInArea(1);
        var area2ExpertsCountBefore = await expertsRegistry.getExpertsCountInArea(2);

        assert.equal(
            area1ExpertsCountBefore,
            3,
            'there should be 3 experts in area 1 initially');
        assert.equal(
            area2ExpertsCountBefore,
            3,
            'there should be 3 experts in area 2 initially');

        await expertsRegistry.remove(expert1, {from: admin});

        var area1ExpertsCountAfter = await expertsRegistry.getExpertsCountInArea(1);
        var area2ExpertsCountAfter = await expertsRegistry.getExpertsCountInArea(2);

        assert.equal(
            area1ExpertsCountAfter,
            2,
            'there should be one expert left in area 1');
        assert.equal(
            area2ExpertsCountAfter,
            2,
            'there should be one expert left in area 2');

        var area1Experts = await expertsRegistry.get(1, [0, 1]);

        assert.equal(
            area1Experts[0],
            expert3,
            'expert 3 should be returned as first in area 1');
        assert.equal(
            area1Experts[1],
            expert2,
            'expert 2 should be returned as second in area 1');

        var area2Experts = await expertsRegistry.get(2, [0, 1]);
        assert.equal(
            area2Experts[0],
            expert3,
            'expert 3 should be returned as first in area 2');
        assert.equal(
            area2Experts[1],
            expert2,
            'expert 2 should be returned as second in area 2');
    });

    it('experts can be disabled' , async function() {
        var areas = [1, 2];
        await expertsRegistry.add(expert1, areas, {from: admin});
        await expertsRegistry.add(expert2, areas, {from: admin});
        await expertsRegistry.add(expert3, areas, {from: admin});

        var area1ExpertsCountBefore = await expertsRegistry.getExpertsCountInArea(1);
        var area2ExpertsCountBefore = await expertsRegistry.getExpertsCountInArea(2);

        assert.equal(
            area1ExpertsCountBefore,
            3,
            'there should be 3 experts in area 1 initially');
        assert.equal(
            area2ExpertsCountBefore,
            3,
            'there should be 3 experts in area 2 initially');

        await expertsRegistry.disable(expert1, {from: expert1});

        var area1ExpertsCountAfter = await expertsRegistry.getExpertsCountInArea(1);
        var area2ExpertsCountAfter = await expertsRegistry.getExpertsCountInArea(2);

        assert.equal(
            area1ExpertsCountAfter,
            2,
            'there should be one expert left in area 1');
        assert.equal(
            area2ExpertsCountAfter,
            2,
            'there should be one expert left in area 2');

        var area1Experts = await expertsRegistry.get(1, [0, 1]);

        assert.equal(
            area1Experts[0],
            expert3,
            'expert 3 should be returned as first in area 1');
        assert.equal(
            area1Experts[1],
            expert2,
            'expert 2 should be returned as second in area 1');

        var area2Experts = await expertsRegistry.get(2, [0, 1]);
        assert.equal(
            area2Experts[0],
            expert3,
            'expert 3 should be returned as first in area 2');
        assert.equal(
            area2Experts[1],
            expert2,
            'expert 2 should be returned as second in area 2');
    });

    it('experts can be enabled' , async function() {
        await expertsRegistry.add(expert1, [1, 2], {from: admin});
        await expertsRegistry.add(expert2, [1, 2], {from: admin});
        await expertsRegistry.add(expert3, [2], {from: admin});

        var area1ExpertsCountBefore = await expertsRegistry.getExpertsCountInArea(1);
        var area2ExpertsCountBefore = await expertsRegistry.getExpertsCountInArea(2);

        assert.equal(
            area1ExpertsCountBefore,
            2,
            'there should be 3 experts in area 1 initially');
        assert.equal(
            area2ExpertsCountBefore,
            3,
            'there should be 3 experts in area 2 initially');

        await expertsRegistry.disable(expert1, {from: expert1});
        await expertsRegistry.enable(expert1, {from: expert1});

        var area1ExpertsCountAfter = await expertsRegistry.getExpertsCountInArea(1);
        var area2ExpertsCountAfter = await expertsRegistry.getExpertsCountInArea(2);

        assert.equal(
            area1ExpertsCountAfter,
            2,
            'there should be the same amount of experts in area 1');
        assert.equal(
            area2ExpertsCountAfter,
            3,
            'there should be the same amount of experts in area 2');
    });

    it('[mock] add experts in list to registry', async function () {
        const expertList = [expert1, expert2, expert3];
        const areas =       [13,      123,     1234];
        console.log('addExperts')        
        await expertsRegistry.addExperts(expertList, areas, {from: owner})
        const expertsInArea1 = await expertsRegistry.expertsByAreaMap(1, 0);
        const expertsInArea2 = await expertsRegistry.expertsByAreaMap(2, 0);
        const expertsInArea3 = await expertsRegistry.expertsByAreaMap(3, 0);
        const expertsInArea4 = await expertsRegistry.expertsByAreaMap(4, 0);

        console.log(expertsInArea1)
        console.log(expertsInArea2)
        console.log(expertsInArea3)
        console.log(expertsInArea4)
    })
});