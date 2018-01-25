var VotingManagerMock = artifacts.require('./mock/VotingManagerMock.sol');
var VotingSprintMock = artifacts.require('./mock/VotingSprintMock.sol');
var BalanceFreezerMock = artifacts.require('./mock/BalanceFreezerMock.sol');
var SmartValleyTokenMock = artifacts.require('./mock/SmartValleyTokenMock.sol');

contract('VotingSprint', async function(accounts) {

    let manager, freezer, token, owner, voter, voter1, voter2, projects, sprint;
    let amount = 120 * (10 ** 18);    
    let minimumProjectCount = 4;    
    let options;

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

    beforeEach(async function() {            
        owner = accounts[1];        
        voter = accounts[3];
        voter1 = accounts[4];
        voter2 = accounts[5];
        freezer = await BalanceFreezerMock.new({from: owner});        
        token = await SmartValleyTokenMock.new(freezer.address, [voter, voter1, voter2, owner], amount, {from: owner});        
        manager = await VotingManagerMock.new(freezer.address, token.address, minimumProjectCount, {from: owner});
        manager.setAcceptanceThresholdPercent(50, {from: owner});
        projects = await fillProjectQueue(minimumProjectCount);
        await manager.createSprint(7, {from: owner});
        sprint = VotingSprintMock.at(await manager.lastSprint());

        options = {
            total_votes: 1,
            vote_per_project: 1,
            project_for_vote: projects[0]
        }                    
    });        

    //type 0 - OK test case, 1 - NOK test case
    var submitVote_TestCases = [
        {type: 0, vote: 10, description: 'should take the vote on the project, some tokens', precondition() {}},
        {type: 0, vote: 120, description: 'should take the vote on the project, maximum tokens', precondition() {}},
        {type: 0, vote: 0.1, description: 'should take the vote on the project, less then one token', precondition() {}},
        {type: 1, vote: 121, description: 'should not take the vote on the project, if not enough tokens', precondition() {}},
        {type: 1, vote: 120.1, description: 'should not take the vote on the project, if not enough less then one token', precondition() {}},
        {type: 1, vote: 0, description: 'should not take the vote on the project with zero tokens', precondition() {}},
        {type: 1, vote: 60, description: 'should not take the vote on the project many times', 
            async precondition() {
                await sprint.submitVote(options.project_for_vote, (this.vote - 10) * (10 ** 18), {from: voter});
            }
        },
        {type: 1, vote: 20, description: 'should not take the vote on the project not in sprint', 
            async precondition() {
                projects.push(createProjectId());
                options.project_for_vote = projects[minimumProjectCount]                
            }
        },
        {type: 0, vote: 40, description: 'should take a vote from investor for many projects in sprint, maximumScore not changed', 
            async precondition() {
                await sprint.submitVote(projects[1], this.vote * (10 ** 18), {from: voter});
                await sprint.submitVote(projects[2], this.vote * (10 ** 18), {from: voter});   
                options.vote_per_project = 3                             
            }
        },
        {type: 0, vote: 60, description: 'should take a votes from investors on the project in sprint, maximumScore must increase', 
            async precondition() {
                await sprint.submitVote(options.project_for_vote, this.vote * (10 ** 18), {from: voter1});
                await sprint.submitVote(options.project_for_vote, this.vote * (10 ** 18), {from: voter2});
                options.total_votes = 3;
            }
        }
    ]

    for(var i = 0; i < submitVote_TestCases.length; i++) {
        submitVote_Test(submitVote_TestCases[i]);
    }

    function submitVote_Test(testCase) {
        it('submitVote ' + testCase.description, async function() {

            await testCase.precondition();

            var project = options.project_for_vote;
            var vote_amount = testCase.vote * (10 ** 18);
            var error = null;

            try {
                await sprint.submitVote(project, vote_amount, {from: voter});
            } catch (err) {
                error = err;
            }
    
            if(testCase.type == 0) {
                assert.equal(await sprint.investorVotes(voter, project), vote_amount, 'vote of project not equal to real vote amount');
                assert.equal(await sprint.maximumScore(), vote_amount * options.total_votes, 'maximumScore not increased');
                assert.equal(await sprint.projectTokenAmounts(project), vote_amount * options.total_votes, 'projectTokenAmounts invalid');
                assert.equal(await sprint.projectsByInvestor(voter, options.vote_per_project - 1), project, 'projectsByInvestor invalid');
                assert.equal(await sprint.investorTokenAmounts(voter), vote_amount, 'investorTokenAmounts invalid');
                assert.equal(await token.getAvailableBalance(voter), amount - vote_amount, 'balance not freezed');
            } else if(testCase.type == 1) {
                assert.notEqual(error, null, 'error should be thrown because requirements not met');
            }            
        });
    }

    it('isAccepted should show status of project in sprint', async function() {
        await sprint.submitVote(projects[0], 24.65 * (10 ** 18), {from: voter});
        await sprint.submitVote(projects[0], 29.45 * (10 ** 18), {from: voter1});
        await sprint.submitVote(projects[0], 45.9 * (10 ** 18), {from: voter2});

        await sprint.submitVote(projects[1], 19.5 * (10 ** 18), {from: voter1});
        await sprint.submitVote(projects[1], 31.5 * (10 ** 18), {from: voter2});

        await sprint.submitVote(projects[2], 49.99999999 * (10 ** 18), {from: voter2});

        assert.isTrue(await sprint.isAccepted(projects[0]), 'project 0 should by accepted');
        assert.isTrue(await sprint.isAccepted(projects[1]), 'project 1 should by accepted');
        assert.isNotTrue(await sprint.isAccepted(projects[2]), 'projects 2 should by not accpeted');
    });

    it('isAccepted should only accept projects from the sprint', async function() {
        var error = null;

        try {
            await sprint.submitVote(createProjectId(), 30 * (10 ** 18), {from: voter});
        } catch (err) {
            error = err;
        }

        assert.notEqual(error, null, 'error should be thrown because projectId not in sprint');
    });

    it('getDetails should return sprint details', async function() {

        var details = await sprint.getDetails();
        var test_start_date = parseInt((Date.now() - 10 * 1000).toString().replace(/\d\d\d$/, ''));

        assert.isTrue(details[0] >= test_start_date, 'start date older then 10 sec');
        assert.isTrue(details[1] == parseInt(details[0]) + 7 * 24 * 60 * 60, 'end date invalid');
        assert.equal(details[2], 50, 'acceptance threshold invalid');
        assert.equal(details[3], 0, 'maximum score should by 0 at start');
        for(var i = 0; i < projects.length; i++) {
            assert.equal(details[4][i], projects[i], 'unexpected project');
        }

        await sprint.submitVote(projects[0], 30.55 * (10 ** 18), {from: voter});
        await sprint.submitVote(projects[0], 30 * (10 ** 18), {from: voter1});
        await sprint.submitVote(projects[0], 40.10 * (10 ** 18), {from: voter2});

        await sprint.submitVote(projects[1], 20 * (10 ** 18), {from: voter1});
        await sprint.submitVote(projects[1], 30 * (10 ** 18), {from: voter2});

        await sprint.submitVote(projects[2], 49 * (10 ** 18), {from: voter2});

        details = await sprint.getDetails();
        
        assert.isTrue(details[0] >= test_start_date, 'start date older then 10 sec');
        assert.isTrue(details[1] == parseInt(details[0]) + 7 * 24 * 60 * 60, 'end date invalid');
        assert.equal(details[2], 50, 'acceptance threshold invalid');
        assert.equal(details[3], 100.65 * (10 ** 18), 'maximum score should by 100.65 * (10 ** 18) at start ' + details[3]);
        for(var i = 0; i < projects.length; i++) {
            assert.equal(details[4][i], projects[i], 'unexpected project');
        }

    });

    it('getInvestorVotes should return projects and amount of tokens', async function() {
        var tokenAmount = 28.574763 * (10 ** 18);
        var projects_for_vote = [projects[0], projects[1], projects[2]];

        var votes = await sprint.getInvestorVotes(voter);          

        assert.equal(votes[0], 0, 'token amount should by 0');
        assert.equal(votes[1].length, 0, 'projects counts should by 0');        

        await sprint.submitVote(projects_for_vote[0], tokenAmount, {from: voter});
        await sprint.submitVote(projects_for_vote[1], 19.234545 * (10 ** 18), {from: voter});
        await sprint.submitVote(projects_for_vote[2], 49.252935 * (10 ** 18), {from: voter});

        var votes = await sprint.getInvestorVotes(voter);

        assert.equal(votes[0], tokenAmount, 'token amount should by equal fist vote');
        for(var i = 0; i < projects_for_vote.length; i++) {
            assert.equal(votes[1][i], projects_for_vote[i], 'unexpected project');
        }
    });

    it('getVote should return vote of investor by projects', async function() {
        var tokenAmount = 28.574763 * (10 ** 18);
        var project_for_vote = projects[0];

        var vote = await sprint.getVote(voter, project_for_vote);

        assert.equal(vote, 0, 'vote of project should by 0, because investor not voting');

        await sprint.submitVote(project_for_vote, tokenAmount, {from: voter});

        vote = await sprint.getVote(voter, project_for_vote);

        assert.equal(vote, tokenAmount, 'vote of project invalid');
    });
        
});