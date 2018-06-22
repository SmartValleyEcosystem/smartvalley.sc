var Scoring = artifacts.require('./Scoring.sol');

contract('Scoring', async function (accounts) {
    let scoring;  
    let owner;
    let scoringManager;
    let amount = 12 * (10 ** 18);
    let etherAmount = 12 * (10 ** 18);
    let reward = 1 * (10 ** 18);
    let areas = [1, 2, 3, 4];
    let areaEstimateRewards = [1 ,1 ,3 ,1];
    let areaExpertCounts = [3, 3, 3, 3];

    function getScoringCost() {
        cost = null;
        for (i = 0; i < areas.length; i++) {
            cost += areaExpertCounts[i] * areaEstimateRewards[i];
        }
        return web3.toWei(cost);
    }

    beforeEach(async function () {
        rewardsWei = [];
        for (i = 0; i < areas.length; i++) {
            rewardsWei.push(web3.toWei(areaEstimateRewards[i]))
        } 
        owner = accounts[9];
        scoringManager = accounts[8];
        scoring = await Scoring.new(areas, areaExpertCounts, rewardsWei,{ from: scoringManager });
        await web3.eth.sendTransaction({from:accounts[8], to:scoring.address, value: web3.toWei(4, "ether")});
    });

    it('When estimates submitted, expert should be rewarded', async function () {
        var area = 3;
        var questions = [1, 2, 3];
        var scores = [10, 5, 0];
        var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3")];

        var initialBalance = await web3.eth.getBalance(accounts[0]);
        await scoring.submitEstimates(accounts[0], area, questions, scores, commentHashes, {from: scoringManager});
        var balance = await web3.eth.getBalance(accounts[0]);
        assert.notEqual(+initialBalance, +balance);
    });

    it('Should get correct scoring cost', async function () {
        var contractCost = await scoring.getScoringCost();
        var cost = getScoringCost();
        assert.equal(+contractCost, +cost, +contractCost +' should be equal '+ +cost);
    });

    // it('Initial state should be correct', async function () {
    //     assert.equal(await scoring.isScored(), false);
    //     assert.equal(await scoring.score(), 0);
    //     assert.equal(await scoring.currentSubmissionsCount(), 0);
    //     assert.equal((await scoring.getEstimates())[0].length, 0);
    //     assert.equal(await scoring.areaSubmissionsCounters(1), 0);
    //     assert.equal(await scoring.areaSubmissionsCounters(2), 0);
    //     assert.equal(await scoring.areaSubmissionsCounters(3), 0);
    //     assert.equal(await scoring.areaSubmissionsCounters(4), 0);
    // });

    // it('When estimates submitted, counters should be updated correctly', async function () {
    //     var area = 3;
    //     var questions = [1, 2, 3];
    //     var scores = [10, 5, 0];
    //     var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3")];

    //     await scoring.submitEstimates(accounts[0], area, questions, scores, commentHashes, reward, {from: scoringManager});

    //     assert.equal(await scoring.currentSubmissionsCount(), 1);
    //     assert.equal((await scoring.getEstimates())[0].length, scores.length);
    //     assert.equal(await scoring.areaSubmissionsCounters(area), 1);
    //     assert.equal(await scoring.isScored(), false);
    // });

    // it('When expert submits estimates in the same category twice, error shound be returned', async function () {
    //     var area = 3;
    //     var questions = [1, 2, 3];
    //     var scores = [10, 5, 0];
    //     var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3")];

    //     await scoring.submitEstimates(accounts[0], area, questions, scores, commentHashes, reward, {from: scoringManager});

    //     var errorMessage = null;
    //     try {
    //         await scoring.submitEstimates(accounts[0], area, questions, scores, commentHashes, reward, {from: scoringManager});
    //     } catch (error) {
    //         errorMessage = error.message;
    //     }

    //     assert.notEqual(errorMessage, null, 'Error must be returned');
    // });

    // it('Expert should be able to submit estimate for different areas', async function () {
    //     var area1 = 2;
    //     var area2 = 3;
    //     var questions = [1, 2, 3];
    //     var scores = [10, 5, 0];
    //     var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3")];

    //     await scoring.submitEstimates(accounts[0], area1, questions, scores, commentHashes, reward, {from: scoringManager});
    //     await scoring.submitEstimates(accounts[0], area2, questions, scores, commentHashes, reward, {from: scoringManager});

    //     assert.equal(await scoring.currentSubmissionsCount(), 2);
    //     assert.equal((await scoring.getEstimates())[0].length, scores.length * 2);
    //     assert.equal(await scoring.areaSubmissionsCounters(area1), 1);
    //     assert.equal(await scoring.areaSubmissionsCounters(area2), 1);

    //     assert.equal(await scoring.isScored(), false);
    // });

    // it('When expert submits estimates for area that was estimated by 3 other experts, error should be returned', async function () {
    //     var area = 1;
    //     var questions = [1, 2, 3];
    //     var scores = [10, 5, 0];
    //     var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3")];

    //     await scoring.submitEstimates(accounts[0], area, questions, scores, commentHashes, reward, {from: scoringManager});
    //     await scoring.submitEstimates(accounts[1], area, questions, scores, commentHashes, reward, {from: scoringManager});
    //     await scoring.submitEstimates(accounts[2], area, questions, scores, commentHashes, reward, {from: scoringManager});

    //     var errorMessage = null;
    //     try {
    //         await scoring.submitEstimates(accounts[3], area, questions, scores, commentHashes, reward, {from: scoringManager});
    //     } catch (error) {
    //         errorMessage = error.message;
    //     }

    //     assert.notEqual(errorMessage, null, 'Error must be returned');
    // });

    // it('When questions array length does not match scores and commentHashes lengths, error should be returned', async function () {
    //     var area = 1;
    //     var questions = [1, 2, 3, 4];
    //     var scores = [10, 5, 0];
    //     var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3")];

    //     var errorMessage = null;
    //     try {
    //         await scoring.submitEstimates(accounts[0], area, questions, scores, commentHashes, reward, {from: scoringManager});
    //     } catch (error) {
    //         errorMessage = error.message;
    //     }

    //     assert.notEqual(errorMessage, null, 'Error must be returned');
    // });

    // it('When scores array length does not match questions and commentHashes lengths, error should be returned', async function () {
    //     var area = 1;
    //     var questions = [1, 2, 3];
    //     var scores = [10, 5, 0, 4];
    //     var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3")];

    //     var errorMessage = null;
    //     try {
    //         await scoring.submitEstimates(accounts[0], area, questions, scores, commentHashes, reward, {from: scoringManager});
    //     } catch (error) {
    //         errorMessage = error.message;
    //     }

    //     assert.notEqual(errorMessage, null, 'Error must be returned');
    // });

    // it('When commentHashes array length does not match questions and scores lengths, error should be returned', async function () {
    //     var area = 1;
    //     var questions = [1, 2, 3];
    //     var scores = [10, 5, 0];
    //     var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3"), web3.sha3("qqq4")];

    //     var errorMessage = null;
    //     try {
    //         await scoring.submitEstimates(accounts[0], area, questions, scores, commentHashes, reward, {from: scoringManager});
    //     } catch (error) {
    //         errorMessage = error.message;
    //     }

    //     assert.notEqual(errorMessage, null, 'Error must be returned');
    // });

    // it('When scoring is estimated by 3 experts in each area, final score should be calculated', async function () {
    //     var questions = [1, 2, 3, 4];
    //     var scores = [4, 5, 6, 7];
    //     var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3"), web3.sha3("qqq4")];
    //     var expectedScore = (scores.reduce((a, b) => a + b, 0)) * 12 / 3;

    //     await scoring.submitEstimates(accounts[0], 1, questions, scores, commentHashes, reward, {from: scoringManager});
    //     await scoring.submitEstimates(accounts[1], 1, questions, scores, commentHashes, reward, {from: scoringManager});
    //     await scoring.submitEstimates(accounts[2], 1, questions, scores, commentHashes, reward, {from: scoringManager});

    //     await scoring.submitEstimates(accounts[0], 2, questions, scores, commentHashes, reward, {from: scoringManager});
    //     await scoring.submitEstimates(accounts[1], 2, questions, scores, commentHashes, reward, {from: scoringManager});
    //     await scoring.submitEstimates(accounts[2], 2, questions, scores, commentHashes, reward, {from: scoringManager});

    //     await scoring.submitEstimates(accounts[0], 3, questions, scores, commentHashes, reward, {from: scoringManager});
    //     await scoring.submitEstimates(accounts[1], 3, questions, scores, commentHashes, reward, {from: scoringManager});
    //     await scoring.submitEstimates(accounts[2], 3, questions, scores, commentHashes, reward, {from: scoringManager});

    //     await scoring.submitEstimates(accounts[0], 4, questions, scores, commentHashes, reward, {from: scoringManager});
    //     await scoring.submitEstimates(accounts[1], 4, questions, scores, commentHashes, reward, {from: scoringManager});
    //     await scoring.submitEstimates(accounts[2], 4, questions, scores, commentHashes, reward, {from: scoringManager});

    //     assert.equal(await scoring.score(), expectedScore);
    //     assert.equal(await scoring.isScored(), true);
    //     assert.equal(await scoring.currentSubmissionsCount(), 12);
    //     assert.equal((await scoring.getEstimates())[0].length, scores.length * 12);
    //     assert.equal(await scoring.areaSubmissionsCounters(1), 3);
    //     assert.equal(await scoring.areaSubmissionsCounters(2), 3);
    //     assert.equal(await scoring.areaSubmissionsCounters(3), 3);
    //     assert.equal(await scoring.areaSubmissionsCounters(4), 3);
    // });

    // it('When expert submits estimates for already scored scoring, error should be returned', async function () {
    //     var questions = [1, 2, 3, 4];
    //     var scores = [4, 5, 6, 7];
    //     var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3"), web3.sha3("qqq4")];

    //     await scoring.submitEstimates(accounts[0], 1, questions, scores, commentHashes, reward, {from: scoringManager});
    //     await scoring.submitEstimates(accounts[1], 1, questions, scores, commentHashes, reward, {from: scoringManager});
    //     await scoring.submitEstimates(accounts[2], 1, questions, scores, commentHashes, reward, {from: scoringManager});

    //     await scoring.submitEstimates(accounts[0], 2, questions, scores, commentHashes, reward, {from: scoringManager});
    //     await scoring.submitEstimates(accounts[1], 2, questions, scores, commentHashes, reward, {from: scoringManager});
    //     await scoring.submitEstimates(accounts[2], 2, questions, scores, commentHashes, reward, {from: scoringManager});

    //     await scoring.submitEstimates(accounts[0], 3, questions, scores, commentHashes, reward, {from: scoringManager});
    //     await scoring.submitEstimates(accounts[1], 3, questions, scores, commentHashes, reward, {from: scoringManager});
    //     await scoring.submitEstimates(accounts[2], 3, questions, scores, commentHashes, reward, {from: scoringManager});

    //     await scoring.submitEstimates(accounts[0], 4, questions, scores, commentHashes, reward, {from: scoringManager});
    //     await scoring.submitEstimates(accounts[1], 4, questions, scores, commentHashes, reward, {from: scoringManager});
    //     await scoring.submitEstimates(accounts[2], 4, questions, scores, commentHashes, reward, {from: scoringManager});

    //     var errorMessage = null;
    //     try {
    //         await scoring.submitEstimates(accounts[3], 4, questions, scores, commentHashes, reward, {from: scoringManager});
    //     } catch (error) {
    //         errorMessage = error.message;
    //     }

    //     assert.notEqual(errorMessage, null, 'Error must be returned');
    // });

    // it('It should be possible to retrieve estimates from contract', async function () {
    //     var expectedQuestions = [1, 2, 3, 4];
    //     var expectedScores = [4, 5, 6, 7];
    //     var commentHashes = [web3.sha3("qqq1"), web3.sha3("qqq2"), web3.sha3("qqq3"), web3.sha3("qqq4")];

    //     await scoring.submitEstimates(accounts[3], 1, expectedQuestions, expectedScores, commentHashes, reward, {from: scoringManager});

    //     var estimatesCount = (await scoring.getEstimates())[0].length;
    //     assert.equal(estimatesCount, expectedQuestions.length);

    //     var estimates = await scoring.getEstimates();

    //     var questions = estimates[0];
    //     var scores = estimates[1];
    //     var experts = estimates[2];
    //     for (let i = 0; i < estimatesCount; i++) {
    //         assert.equal(questions[i], expectedQuestions[i]);
    //         assert.equal(scores[i], expectedScores[i]);
    //         assert.equal(experts[i], accounts[3]);
    //     }
    // });
});
