var ProjectMock = artifacts.require('./mock/ProjectMock.sol');

contract('Project', async function (accounts) {
    let project;
    let owner;

    beforeEach(async function () {
        owner = accounts[9];
        project = await ProjectMock.new({ from: owner });
    });

    it('Initial state should be correct', async function () {
        assert.equal(await project.isScored(), false);
        assert.equal(await project.score(), 0);
        assert.equal(await project.submissionsCount(), 0);
        assert.equal(await project.getEstimatesCount(), 0);
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

        await project.submitEstimates(area, questions, scores, commentHashes);

        assert.equal(await project.submissionsCount(), 1);
        assert.equal(await project.getEstimatesCount(), scores.length);
        assert.equal(await project.areaSubmissionsCounters(area), 1);
        assert.equal(await project.isScored(), false);
    });

    it('When expert submits estimates in the same category twice, error shound be returned', async function () {
        var area = 3;
        var questions = [1, 2, 3];
        var scores = [10, 5, 0];
        var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3")];

        await project.submitEstimates(area, questions, scores, commentHashes);

        var errorMessage = null;
        try {
            await project.submitEstimates(area, questions, scores, commentHashes);
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

        await project.submitEstimates(area1, questions, scores, commentHashes);
        await project.submitEstimates(area2, questions, scores, commentHashes);

        assert.equal(await project.submissionsCount(), 2);
        assert.equal(await project.getEstimatesCount(), scores.length * 2);
        assert.equal(await project.areaSubmissionsCounters(area1), 1);
        assert.equal(await project.areaSubmissionsCounters(area2), 1);

        assert.equal(await project.isScored(), false);
    });

    it('When expert submits estimates for area that was estimated by 3 other experts, error should be returned', async function () {
        var area = 1;
        var questions = [1, 2, 3];
        var scores = [10, 5, 0];
        var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3")];

        await project.submitEstimates(area, questions, scores, commentHashes, { from: accounts[0] });
        await project.submitEstimates(area, questions, scores, commentHashes, { from: accounts[1] });
        await project.submitEstimates(area, questions, scores, commentHashes, { from: accounts[2] });

        var errorMessage = null;
        try {
            await project.submitEstimates(area, questions, scores, commentHashes, { from: accounts[3] });
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
            await project.submitEstimates(area, questions, scores, commentHashes);
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
            await project.submitEstimates(area, questions, scores, commentHashes);
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
            await project.submitEstimates(area, questions, scores, commentHashes);
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

        await project.submitEstimates(1, questions, scores, commentHashes, { from: accounts[0] });
        await project.submitEstimates(1, questions, scores, commentHashes, { from: accounts[1] });
        await project.submitEstimates(1, questions, scores, commentHashes, { from: accounts[2] });

        await project.submitEstimates(2, questions, scores, commentHashes, { from: accounts[0] });
        await project.submitEstimates(2, questions, scores, commentHashes, { from: accounts[1] });
        await project.submitEstimates(2, questions, scores, commentHashes, { from: accounts[2] });

        await project.submitEstimates(3, questions, scores, commentHashes, { from: accounts[0] });
        await project.submitEstimates(3, questions, scores, commentHashes, { from: accounts[1] });
        await project.submitEstimates(3, questions, scores, commentHashes, { from: accounts[2] });

        await project.submitEstimates(4, questions, scores, commentHashes, { from: accounts[0] });
        await project.submitEstimates(4, questions, scores, commentHashes, { from: accounts[1] });
        await project.submitEstimates(4, questions, scores, commentHashes, { from: accounts[2] });

        assert.equal(await project.score(), expectedScore);
        assert.equal(await project.isScored(), true);
        assert.equal(await project.submissionsCount(), 12);
        assert.equal(await project.getEstimatesCount(), scores.length * 12);
        assert.equal(await project.areaSubmissionsCounters(1), 3);
        assert.equal(await project.areaSubmissionsCounters(2), 3);
        assert.equal(await project.areaSubmissionsCounters(3), 3);
        assert.equal(await project.areaSubmissionsCounters(4), 3);
    });

    it('When expert submits estimates for already scored project, error should be returned', async function () {
        var questions = [1, 2, 3, 4];
        var scores = [4, 5, 6, 7];
        var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3"), web3.sha3("qqq4")];

        await project.submitEstimates(1, questions, scores, commentHashes, { from: accounts[0] });
        await project.submitEstimates(1, questions, scores, commentHashes, { from: accounts[1] });
        await project.submitEstimates(1, questions, scores, commentHashes, { from: accounts[2] });

        await project.submitEstimates(2, questions, scores, commentHashes, { from: accounts[0] });
        await project.submitEstimates(2, questions, scores, commentHashes, { from: accounts[1] });
        await project.submitEstimates(2, questions, scores, commentHashes, { from: accounts[2] });

        await project.submitEstimates(3, questions, scores, commentHashes, { from: accounts[0] });
        await project.submitEstimates(3, questions, scores, commentHashes, { from: accounts[1] });
        await project.submitEstimates(3, questions, scores, commentHashes, { from: accounts[2] });

        await project.submitEstimates(4, questions, scores, commentHashes, { from: accounts[0] });
        await project.submitEstimates(4, questions, scores, commentHashes, { from: accounts[1] });
        await project.submitEstimates(4, questions, scores, commentHashes, { from: accounts[2] });

        var errorMessage = null;
        try {
            await project.submitEstimates(4, questions, scores, commentHashes, { from: accounts[3] });
        } catch (error) {
            errorMessage = error.message;
        }

        assert.notEqual(errorMessage, null, 'Error must be returned');
    });

    it('It should be possible to retrieve estimates from contract', async function () {
        var expectedQuestions = [1, 2, 3, 4];
        var expectedScores = [4, 5, 6, 7];
        var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3"), web3.sha3("qqq4")];

        await project.submitEstimates(1, expectedQuestions, expectedScores, commentHashes);

        var estimatesCount = await project.getEstimatesCount();
        assert.equal(estimatesCount, expectedQuestions.length);

        var estimates = await project.getEstimates();

        var questions = estimates[0];
        var scores = estimates[1];
        for (let i = 0; i < estimatesCount; i++) {
            assert.equal(questions[i], expectedQuestions[i]);
            assert.equal(scores[i], expectedScores[i]);
        }
    });
});
