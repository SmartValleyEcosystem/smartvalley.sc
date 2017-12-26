var ProjectMock = artifacts.require('./mock/ProjectMock.sol');
var SmartValleyTokenMock = artifacts.require("./mock/SmartValleyTokenMock.sol");

contract('Project', async function (accounts) {
    let project;
    let token;
    let owner;
    let scoring;
    let amount = 120 * (10 ** 18);
    let tokensAmount = 120 * (10 ** 18);
    let reward = 10 * (10 ** 18);

    beforeEach(async function () {
        owner = accounts[9];
        scoring = accounts[8];
        token = await SmartValleyTokenMock.new(owner, amount, { from: owner });
        project = await ProjectMock.new(token.address, scoring, { from: owner });

        await token.setMinter(owner, {from: owner});
        await token.mintTokens(project.address, tokensAmount, {from: owner});
    });

    it('Initial state should be correct', async function () {
        assert.equal(await project.isScored(), false);
        assert.equal(await project.score(), 0);
        assert.equal(await project.submissionsCount(), 0);
        assert.equal((await project.getEstimates())[0].length, 0);
        assert.equal(await project.areaSubmissionsCounters(1), 0);
        assert.equal(await project.areaSubmissionsCounters(2), 0);
        assert.equal(await project.areaSubmissionsCounters(3), 0);
        assert.equal(await project.areaSubmissionsCounters(4), 0);
    });

    it('When estimates submitted, counters should be updated correctly', async function () {
        var area = 3;
        var questions = [1, 2, 3];
        var scores = [10, 5, 0];
        var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3")];

        await project.submitEstimates(accounts[0], area, questions, scores, commentHashes, {from: scoring});

        assert.equal(await project.submissionsCount(), 1);
        assert.equal((await project.getEstimates())[0].length, scores.length);
        assert.equal(await project.areaSubmissionsCounters(area), 1);
        assert.equal(await project.isScored(), false);
    });

    it('When expert submits estimates in the same category twice, error shound be returned', async function () {
        var area = 3;
        var questions = [1, 2, 3];
        var scores = [10, 5, 0];
        var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3")];

        await project.submitEstimates(accounts[0], area, questions, scores, commentHashes, {from: scoring});

        var errorMessage = null;
        try {
            await project.submitEstimates(accounts[0], area, questions, scores, commentHashes, {from: scoring});
        } catch (error) {
            errorMessage = error.message;
        }

        assert.notEqual(errorMessage, null, 'Error must be returned');
    });

    it('Expert should be able to submit estimate for different areas', async function () {
        var area1 = 2;
        var area2 = 3;
        var questions = [1, 2, 3];
        var scores = [10, 5, 0];
        var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3")];

        await project.submitEstimates(accounts[0], area1, questions, scores, commentHashes, {from: scoring});
        await project.submitEstimates(accounts[0], area2, questions, scores, commentHashes, {from: scoring});

        assert.equal(await project.submissionsCount(), 2);
        assert.equal((await project.getEstimates())[0].length, scores.length * 2);
        assert.equal(await project.areaSubmissionsCounters(area1), 1);
        assert.equal(await project.areaSubmissionsCounters(area2), 1);

        assert.equal(await project.isScored(), false);
    });

    it('When expert submits estimates for area that was estimated by 3 other experts, error should be returned', async function () {
        var area = 1;
        var questions = [1, 2, 3];
        var scores = [10, 5, 0];
        var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3")];

        await project.submitEstimates(accounts[0], area, questions, scores, commentHashes, {from: scoring});
        await project.submitEstimates(accounts[1], area, questions, scores, commentHashes, {from: scoring});
        await project.submitEstimates(accounts[2], area, questions, scores, commentHashes, {from: scoring});

        var errorMessage = null;
        try {
            await project.submitEstimates(accounts[3], area, questions, scores, commentHashes, {from: scoring});
        } catch (error) {
            errorMessage = error.message;
        }

        assert.notEqual(errorMessage, null, 'Error must be returned');
    });

    it('When questions array length does not match scores and commentHashes lengths, error should be returned', async function () {
        var area = 1;
        var questions = [1, 2, 3, 4];
        var scores = [10, 5, 0];
        var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3")];

        var errorMessage = null;
        try {
            await project.submitEstimates(accounts[0], area, questions, scores, commentHashes, {from: scoring});
        } catch (error) {
            errorMessage = error.message;
        }

        assert.notEqual(errorMessage, null, 'Error must be returned');
    });

    it('When scores array length does not match questions and commentHashes lengths, error should be returned', async function () {
        var area = 1;
        var questions = [1, 2, 3];
        var scores = [10, 5, 0, 4];
        var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3")];

        var errorMessage = null;
        try {
            await project.submitEstimates(accounts[0], area, questions, scores, commentHashes, {from: scoring});
        } catch (error) {
            errorMessage = error.message;
        }

        assert.notEqual(errorMessage, null, 'Error must be returned');
    });

    it('When commentHashes array length does not match questions and scores lengths, error should be returned', async function () {
        var area = 1;
        var questions = [1, 2, 3];
        var scores = [10, 5, 0];
        var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3"), web3.sha3("qqq4")];

        var errorMessage = null;
        try {
            await project.submitEstimates(accounts[0], area, questions, scores, commentHashes, {from: scoring});
        } catch (error) {
            errorMessage = error.message;
        }

        assert.notEqual(errorMessage, null, 'Error must be returned');
    });

    it('When project is estimated by 3 experts in each area, final score should be calculated', async function () {
        var questions = [1, 2, 3, 4];
        var scores = [4, 5, 6, 7];
        var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3"), web3.sha3("qqq4")];
        var expectedScore = (scores.reduce((a, b) => a + b, 0)) * 12 / 3;

        await project.submitEstimates(accounts[0], 1, questions, scores, commentHashes, {from: scoring});
        await project.submitEstimates(accounts[1], 1, questions, scores, commentHashes, {from: scoring});
        await project.submitEstimates(accounts[2], 1, questions, scores, commentHashes, {from: scoring});

        await project.submitEstimates(accounts[0], 2, questions, scores, commentHashes, {from: scoring});
        await project.submitEstimates(accounts[1], 2, questions, scores, commentHashes, {from: scoring});
        await project.submitEstimates(accounts[2], 2, questions, scores, commentHashes, {from: scoring});

        await project.submitEstimates(accounts[0], 3, questions, scores, commentHashes, {from: scoring});
        await project.submitEstimates(accounts[1], 3, questions, scores, commentHashes, {from: scoring});
        await project.submitEstimates(accounts[2], 3, questions, scores, commentHashes, {from: scoring});

        await project.submitEstimates(accounts[0], 4, questions, scores, commentHashes, {from: scoring});
        await project.submitEstimates(accounts[1], 4, questions, scores, commentHashes, {from: scoring});
        await project.submitEstimates(accounts[2], 4, questions, scores, commentHashes, {from: scoring});

        assert.equal(await project.score(), expectedScore);
        assert.equal(await project.isScored(), true);
        assert.equal(await project.submissionsCount(), 12);
        assert.equal((await project.getEstimates())[0].length, scores.length * 12);
        assert.equal(await project.areaSubmissionsCounters(1), 3);
        assert.equal(await project.areaSubmissionsCounters(2), 3);
        assert.equal(await project.areaSubmissionsCounters(3), 3);
        assert.equal(await project.areaSubmissionsCounters(4), 3);
    });

    it('When expert submits estimates for already scored project, error should be returned', async function () {
        var questions = [1, 2, 3, 4];
        var scores = [4, 5, 6, 7];
        var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3"), web3.sha3("qqq4")];

        await project.submitEstimates(accounts[0], 1, questions, scores, commentHashes, {from: scoring});
        await project.submitEstimates(accounts[1], 1, questions, scores, commentHashes, {from: scoring});
        await project.submitEstimates(accounts[2], 1, questions, scores, commentHashes, {from: scoring});

        await project.submitEstimates(accounts[0], 2, questions, scores, commentHashes, {from: scoring});
        await project.submitEstimates(accounts[1], 2, questions, scores, commentHashes, {from: scoring});
        await project.submitEstimates(accounts[2], 2, questions, scores, commentHashes, {from: scoring});

        await project.submitEstimates(accounts[0], 3, questions, scores, commentHashes, {from: scoring});
        await project.submitEstimates(accounts[1], 3, questions, scores, commentHashes, {from: scoring});
        await project.submitEstimates(accounts[2], 3, questions, scores, commentHashes, {from: scoring});

        await project.submitEstimates(accounts[0], 4, questions, scores, commentHashes, {from: scoring});
        await project.submitEstimates(accounts[1], 4, questions, scores, commentHashes, {from: scoring});
        await project.submitEstimates(accounts[2], 4, questions, scores, commentHashes, {from: scoring});

        var errorMessage = null;
        try {
            await project.submitEstimates(accounts[3], 4, questions, scores, commentHashes, {from: scoring});
        } catch (error) {
            errorMessage = error.message;
        }

        assert.notEqual(errorMessage, null, 'Error must be returned');
    });

    it('It should be possible to retrieve estimates from contract', async function () {
        var expectedQuestions = [1, 2, 3, 4];
        var expectedScores = [4, 5, 6, 7];
        var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3"), web3.sha3("qqq4")];

        await project.submitEstimates(accounts[3], 1, expectedQuestions, expectedScores, commentHashes, {from: scoring});

        var estimatesCount = (await project.getEstimates())[0].length;
        assert.equal(estimatesCount, expectedQuestions.length);

        var estimates = await project.getEstimates();

        var questions = estimates[0];
        var scores = estimates[1];
        var experts = estimates[2];
        for (let i = 0; i < estimatesCount; i++) {
            assert.equal(questions[i], expectedQuestions[i]);
            assert.equal(scores[i], expectedScores[i]);
            assert.equal(experts[i], accounts[3]);
        }
    });
});
