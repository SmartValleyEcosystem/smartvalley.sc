pragma solidity ^ 0.4.24;

import "../ExpertsRegistry.sol";

contract ExpertsRegistryMock is ExpertsRegistry {

    constructor(address _administratorsRegistryAddress, address _scoringParametersProviderAddress) ExpertsRegistry(_administratorsRegistryAddress, _scoringParametersProviderAddress) public {
    }

    function get(uint _area, uint[] _indices) public view returns(address[]) {
        address[] memory result = new address[](_indices.length);
        for (uint i = 0; i < _indices.length; i++) {
            result[i] = expertsByAreaMap[_area][_indices[i]];
        }
        return result;
    }

    function addExperts(address[] _expertList, uint[] _areas) external {
        for (uint i = 0; i < _expertList.length; i++) {
            add(_expertList[i], _areas);
        }
    }
}