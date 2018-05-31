pragma solidity ^ 0.4.23;

interface PreviousExpertsRegistry {
    function expertsByAreaMap(uint) external returns(address[]);
    function availableAreas() external returns(uint[]);
    function getApplications() external returns(address[], uint[]);
    function getExpertsCountInArea(uint) external returns(uint);
    function getExpertsIndices(uint, address[]) external returns(uint[]);
    function getExpertsInArea(uint) external returns(address[]);
    function getApplicationHash(address) external returns(bytes32);
}