pragma solidity ^ 0.4.18;

import "../ExpertsSelector.sol";

contract ExpertsSelectorMock is ExpertsSelector {

    function ExpertsSelectorMock(address _expertsRegistryAddress) public ExpertsSelector(_expertsRegistryAddress) {
    }
}