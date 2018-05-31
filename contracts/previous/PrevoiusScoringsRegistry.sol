pragma solidity ^ 0.4.23;

interface PrevoiusScoringsRegistry {
    function getScoringsCount() public returns(uint);
    function getProjectIdByIndex(uint _index) public returns(uint);
    function getScoringAreas(uint _projectId) public returns(uint[]);
    function getPendingOffersExpirationTimestamp(uint _projectId) external returns(uint);
    function getScoringAddressByIndex(uint _index) public returns(address);
    function getRequiredExpertsCount(uint _projectId, uint _area) public returns (uint);
    function getOffers(uint _projectId, uint _area) public returns(address[]);
    function getOfferState(uint _projectId, uint _area, address _expert) public returns(uint);
}