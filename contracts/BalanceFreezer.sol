pragma solidity ^ 0.4.24;

contract BalanceFreezer {

    mapping(address => FrozenBalance[]) public frozenBalances;

    struct FrozenBalance {
        uint amount;
        uint endTime;
    }

    function freeze(uint _amountWithDecimals, uint _durationDays) external {
        require(_amountWithDecimals > 0 && _durationDays > 0);

        address account = tx.origin;

        removeExpiredRecords(account);
        addRecord(account, _amountWithDecimals, _durationDays);
    }

    function getFrozenAmount(address _account) external view returns (uint) {
        FrozenBalance[] memory currentFrozenBalances = frozenBalances[_account];
        uint frozenAmount = 0;
        for (uint i = 0; i < currentFrozenBalances.length; i++) {
            FrozenBalance memory currentFrozenBalance = currentFrozenBalances[i];
            if (now < currentFrozenBalance.endTime) {
                frozenAmount += currentFrozenBalance.amount;
            }
        }
        return frozenAmount;
    }

    function removeExpiredRecords(address _account) private {
        FrozenBalance[] storage currentFrozenBalances = frozenBalances[_account];
        for (uint i = 0; i < currentFrozenBalances.length; i++) {
            if (now >= currentFrozenBalances[i].endTime) {
                currentFrozenBalances[i] = currentFrozenBalances[currentFrozenBalances.length - 1];
                currentFrozenBalances.length --;
                i--;
            }
        }
    }

    function addRecord(address _account, uint _amountWithDecimals, uint _durationDays) private {
        frozenBalances[_account].push(FrozenBalance(_amountWithDecimals, now + _durationDays * 1 days));
    }
}