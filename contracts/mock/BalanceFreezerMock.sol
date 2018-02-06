pragma solidity ^ 0.4.18;

import "../BalanceFreezer.sol";

contract BalanceFreezerMock is BalanceFreezer {

    function rewindTime(address _address, uint _days) external {
        FrozenBalance[] storage currentFrozenBalances = frozenBalances[_address];

        for (uint i = 0; i < currentFrozenBalances.length; i++) {
            var currentFrozenBalance = currentFrozenBalances[i];
            currentFrozenBalance.endTime = currentFrozenBalance.endTime + _days * 1 days;
        }
    }
}