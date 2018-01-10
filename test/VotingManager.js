var VotingManagerMock = artifacts.require('./mock/VotingManagerMock.sol');

contract('VotingManager', async function(accounts) {

    let manager;

    beforeEach(async function(){
        manager = await VotingManagerMock.new();
    });

    it('enqueueProject adds the project id to the projectsQueue' , async function() {
        const expectedId = Math.floor(Math.random() * 100000000);
        await manager.enqueueProject(expectedId);

        const addedId = await manager.projectsQueue(0);

        assert.equal(addedId, expectedId);
    });

    it('enqueueProject does not add the same project id multiple times' , async function() {
        const projectId = Math.floor(Math.random() * 100000000);
        await manager.enqueueProject(projectId);

        var errorMessage = null;
        try {
            await manager.enqueueProject(projectId);
        } catch (error) {
            errorMessage = error.message;
        }

        assert.notEqual(errorMessage, null, 'Error must be returned');
    });
});