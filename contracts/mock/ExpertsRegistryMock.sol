pragma solidity ^ 0.4.18;

import "../ExpertsRegistry.sol";

contract ExpertsRegistryMock is ExpertsRegistry {
    function ExpertsRegistryMock(address _administratorsRegistryAddress, uint[] _areas) ExpertsRegistry(_administratorsRegistryAddress, _areas) public {
    }

    function get(uint _area, uint[] _indices) public view returns(address[]) {
        address[] memory result = new address[](_indices.length);
        for (uint i = 0; i < _indices.length; i++) {
            result[i] = areaExpertsMap[_area][_indices[i]];
        }
        return result;
    }
}