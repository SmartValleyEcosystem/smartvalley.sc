pragma solidity ^ 0.4.22;

import "../ExpertsRegistry.sol";

contract ExpertsRegistryMock is ExpertsRegistry {

    constructor(address _administratorsRegistryAddress, uint[] _areas) ExpertsRegistry(_administratorsRegistryAddress, _areas) public {
    }

    event EventLog(uint n);

    function get(uint _area, uint[] _indices) public view returns(address[]) {
        address[] memory result = new address[](_indices.length);
        for (uint i = 0; i < _indices.length; i++) {
            result[i] = expertsByAreaMap[_area][_indices[i]];
        }
        return result;
    }

    function addExperts(address[] _expertList, uint[] _areas) external {
        for (uint i = 0; i < _areas.length; i++) {
            uint[] memory areas;
            if (_areas[i] == 12) {
                areas = new uint[](2);
                areas[0] = 1;
                areas[1] = 2;
            } else if (_areas[i] == 13) {
                areas = new uint[](2);
                areas[0] = 1;
                areas[1] = 3;
            } else if (_areas[i] == 14) {
                areas = new uint[](2);
                areas[0] = 1;
                areas[1] = 4;
            } else if (_areas[i] == 23) {
                areas = new uint[](2);
                areas[0] = 2;
                areas[1] = 3;
            } else if (_areas[i] == 24) {
                areas = new uint[](2);
                areas[0] = 2;
                areas[1] = 4;
            } else if (_areas[i] == 34) {
                areas = new uint[](2);
                areas[0] = 3;
                areas[1] = 4;
            } else if (_areas[i] == 123) {
                areas = new uint[](3);
                areas[0] = 1;
                areas[1] = 2;
                areas[2] = 3;
            } else if (_areas[i] == 124) {
                areas = new uint[](3);
                areas[0] = 1;
                areas[1] = 2;
                areas[2] = 4;
            } else if (_areas[i] == 234) {
                areas = new uint[](3);
                areas[0] = 2;
                areas[1] = 3;
                areas[2] = 4;
            } else if (_areas[i] == 134) {
                areas = new uint[](3);
                areas[0] = 1;
                areas[1] = 3;
                areas[2] = 4;
            } else if (_areas[i] == 1234) {
                areas = new uint[](4);
                areas[0] = 1;
                areas[1] = 2;
                areas[2] = 3;
                areas[3] = 4;
            }

            expertsMap[_expertList[i]].exists = true;

            for (uint x = 0; x < areas.length; x++) {
                //require(!expertsMap[_expertList[i]].areas[areas[x]].approved);
                expertsByAreaMap[areas[x]].push(_expertList[i]);
                expertsMap[_expertList[i]].areas[areas[x]].approved = true;
                expertsMap[_expertList[i]].areas[areas[x]].index = expertsByAreaMap[areas[x]].length - 1;
                expertsMap[_expertList[i]].enabled = true;
            }
        }
    }
}