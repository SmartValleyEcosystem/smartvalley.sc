pragma solidity ^ 0.4.18;

import "../ExpertsRegistry.sol";

contract ExpertsRegistryMock is ExpertsRegistry {
    function ExpertsRegistryMock(address _administratorsRegistryAddress, uint[] _areas) ExpertsRegistry(_administratorsRegistryAddress, _areas) public {
    }
}