var VotingManagerMock = artifacts.require('./mock/VotingManagerMock.sol');
var VotingSprintMock = artifacts.require('./mock/VotingSprintMock.sol');
var BalanceFreezerMock = artifacts.require('./mock/BalanceFreezerMock.sol');
var SmartValleyTokenMock = artifacts.require('./mock/SmartValleyTokenMock.sol');

contract('VotingManager', async function(accounts) {

    let manager, freezer, token, owner, options;
    let amount = 120 * (10 ** 18);
    let minimumProjectCount = 4;

    function createProjectId() {
        return Math.floor(Math.random() * (100000000 - 1000000 + 1)) + 1000000;
    }

    async function fillProjectQueue(count) {
        var enqueuedProjects = [];
        for(var i = 0; i < count; i++) {
            var project_id = createProjectId();
            await manager.enqueueProject(project_id);
            enqueuedProjects.push(project_id);
        }
        return enqueuedProjects;
    }

    beforeEach(async function(){
        owner = accounts[8];
        freezer = await BalanceFreezerMock.new({from: owner});
        token = await SmartValleyTokenMock.new(freezer.address, [owner], amount, {from: owner});
        manager = await VotingManagerMock.new(freezer.address, token.address, minimumProjectCount, {from: owner});
        manager.setAcceptanceThresholdPercent(50, {from: owner});

        options = {
            count_of_projects: 1
        }
    });

    it('enqueueProject adds the project id to the projectsQueue' , async function() {
        const project_id = createProjectId();
        await manager.enqueueProject(project_id);

        const addedId = await manager.projectsQueue(0);

        assert.equal(addedId, project_id);
    });

    it('enqueueProject does not add the same project id multiple times' , async function() {
        const project_id = createProjectId();
        await manager.enqueueProject(project_id);

        var errorMessage = null;
        try {
            await manager.enqueueProject(project_id);
        } catch (error) {
            errorMessage = error.message;
        }

        assert.notEqual(errorMessage, null, 'Error must be returned');
    });

    //type 0 - OK test case, 1 - NOK test case
    var createSprint_TestCases = [
        {type: 0, count: 4, description: 'should create the Voting Sprint with minimum count of projects', precondition() {}},
        {type: 0, count: 10, description: 'should create the Voting Sprint with more then minimum count of projects', precondition() {}},
        {type: 1, count: 3, description: 'should not create Voting Sptint with less then minimum count of projects', precondition() {}},
        {type: 1, count: 6, description: 'should not create Voting Sptint if the previous sprint not finished', 
            async precondition() {
                await fillProjectQueue(this.count);
                await manager.createSprint(2, {from: owner});
            }
        },
        {type: 0, count: 6, description: 'should create Voting Sprint if the previous sprint finished',
            async precondition() {
                await fillProjectQueue(this.count);
                await manager.createSprintMock(2, {from: owner});
                var sprint_address = await manager.lastSprint();
                var sprint = VotingSprintMock.at(sprint_address);
                await sprint.rewindTime(-2);
                options.count_of_projects = 2;
            }
        }
    ]

    for(var i = 0; i < createSprint_TestCases.length; i++) {
        createSprint_Test(createSprint_TestCases[i]);
    }

    function createSprint_Test(testCase) {
        it('createSprint ' + testCase.description, async function() {
            const count = testCase.count;
            const duration = 4;
            var error = null;

            await testCase.precondition();

            var projects = await fillProjectQueue(count);

            try {
                await manager.createSprint(duration, {from: owner});
            } catch (err) {
                error = err;
            }

            if (testCase.type == 0) {
                assert.equal((await manager.getProjectsQueue()).length, 0, 'error, projects queue should by empty');
                assert.equal(await manager.sprints(options.count_of_projects - 1), await manager.lastSprint(), 'error, sprints lsit should contain new created sprint');

                var new_sprint_address = await manager.lastSprint();
                var new_sprint = VotingSprintMock.at(new_sprint_address);
                for(var i = 0; i < count; i++) {
                    assert.equal(await new_sprint.projectIds(i), projects[i], 'project id not in sprint');
                }

            } else if (testCase.type == 1) {
                assert.notEqual(error, null, 'error should be thrown because requirements not met');

                for(var i = 0; i < count; i++) {
                    assert.equal(await manager.projectsQueue(i), projects[i], 'error, project queue should not by empty');
                }
            } 

        });
    }    

    it('getProjectsQueue should return an array of all project ids that are waitng start of the sprint', async function(){
        var count_of_projects = 4;

        var queue = await manager.getProjectsQueue();
        assert.equal(queue.length, 0, 'error, queue not empty at startup');

        var projects = await fillProjectQueue(count_of_projects);

        queue = await manager.getProjectsQueue();
        for(var i = 0; i < count_of_projects; i++) {
            assert.equal(queue[i], projects[i], 'error, project not in queue');
        }

    });

    it('getSprints should return an array of all sprints', async function() {

        var sprints = await manager.getSprints();
        assert.equal(sprints.length, 0, 'error, queue not empty at startup');

        for(var i = 0; i < 3; i++) {
            await fillProjectQueue(4);
            await manager.createSprintMock(2, {from: owner});
            var sprint = VotingSprintMock.at(await manager.lastSprint());
            sprints = await manager.getSprints();
            assert.equal(sprints.length, i + 1, 'error, queue length invalid');
            assert.equal(sprints[i], sprint.address, 'error, unexpected sprint address in queue');
            await sprint.rewindTime(-2);
        }
    });
});