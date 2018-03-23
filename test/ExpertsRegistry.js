var AdministratorsRegistryMock = artifacts.require('./mock/AdministratorsRegistryMock.sol');
var ExpertsRegistryMock = artifacts.require('./mock/ExpertsRegistryMock.sol');

contract('ExpertsRegistry', async function(accounts) {
    let owner;
    let admin;
    let expert1;
    let expert2;
    let expert3;

    let expertsRegistry;

    beforeEach(async function(){
        owner = accounts[7];
        admin = accounts[6];
        expert1 = accounts[5];
        expert2 = accounts[4];
        expert3 = accounts[3];

        let administratorsRegistry = await AdministratorsRegistryMock.new({from: owner});
        administratorsRegistry.add(admin, {from: owner});

        let areas = [1, 2, 3, 4, 5];
        expertsRegistry = await ExpertsRegistryMock.new(administratorsRegistry.address, areas, {from: owner});
    });

    it('application can be submitted by expert' , async function() {
        var areas = [1, 2];
        await expertsRegistry.apply(areas, {from: expert1});

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
        await expertsRegistry.apply(expert2Areas, {from: expert2});

        var expert1Areas = [1, 2, 3, 4];
        await expertsRegistry.apply(expert1Areas, {from: expert1});

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
            await expertsRegistry.areaExpertsMap(2, 0),
            expert1,
            'expert was not added to area 2 list at proper position');
        assert.equal(
            await expertsRegistry.areaExpertsMap(4, 0),
            expert1,
            'expert was not added to area 2 list at proper position');

        var applications = await expertsRegistry.getApplications({from: owner});
        assert.equal(
            applications[0].length,
            expert2Areas.length,
            'there are only expert 2 applications left');
    });

    it('expert can be added by admin' , async function() {
        var areas = [1, 2];
        await expertsRegistry.add(expert1, areas, {from: admin});

        assert.equal(
            await expertsRegistry.areaExpertsMap(1, 0),
            expert1,
            'expert was not added to area 1 list at proper position');
        assert.equal(
            await expertsRegistry.areaExpertsMap(2, 0),
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
        const expertsInArea1 = await expertsRegistry.areaExpertsMap(1, 0);
        const expertsInArea2 = await expertsRegistry.areaExpertsMap(2, 0);
        const expertsInArea3 = await expertsRegistry.areaExpertsMap(3, 0);
        const expertsInArea4 = await expertsRegistry.areaExpertsMap(4, 0);

        console.log(expertsInArea1)
        console.log(expertsInArea2)
        console.log(expertsInArea3)
        console.log(expertsInArea4)

    })
});