pragma solidity ^ 0.4.18;

contract BalanceFreezer {

    mapping(address => FrozenBalance[]) public frozenBalances;

    struct FrozenBalance {
        uint amount;
        uint endTime;
    }

    function freeze(uint _amountWithDecimals, uint _durationDays) external {
        require(_amountWithDecimals > 0 && _durationDays > 0);

        //remove not actual records
        FrozenBalance[] storage currentFrozenBalances = frozenBalances[tx.origin];
        for (uint i = 0; i < currentFrozenBalances.length; i++) {
            var currentFrozenBalance = currentFrozenBalances[i];
            if (now >= currentFrozenBalance.endTime) {
                currentFrozenBalances[i] = currentFrozenBalances[currentFrozenBalances.length - 1];
                currentFrozenBalances.length --;
                i--;
            }
        }

        currentFrozenBalances.push(FrozenBalance(_amountWithDecimals, now + _durationDays * 1 days));                   
    }

    function getFrozenAmount(address _address) external constant returns (uint) {
        FrozenBalance[] memory currentFrozenBalances = frozenBalances[_address];
        uint frozenAmount = 0;
        for (uint i = 0; i < currentFrozenBalances.length; i++) {
            var currentFrozenBalance = currentFrozenBalances[i];
            if (now < currentFrozenBalance.endTime) {
                frozenAmount += currentFrozenBalance.amount;
            }
        }
        return frozenAmount;
    }
}