pragma solidity ^ 0.4.18;

contract BalanceFreezer {     
    
    mapping(address => FrozenBalance[]) public frozenBalances;

    struct FrozenBalance {
        uint amount;
        uint endTime;
    }     

    function freeze(uint _amount, uint _durationDays) external { 
        require(_amount > 0 && _durationDays > 0);
        frozenBalances[tx.origin].push(FrozenBalance(_amount, now + _durationDays * 1 days));                   
    }

    function getFrozenAmount(address _address) public returns (uint) {
        FrozenBalance[] storage currentFrozenBalances = frozenBalances[_address];
        uint frozenAmount = 0;
        for (uint i = 0; i < currentFrozenBalances.length; i++) {
            var currentFrozenBalance = currentFrozenBalances[i];
            if (now < currentFrozenBalance.endTime) {
                frozenAmount += currentFrozenBalance.amount;
            } else {                
                currentFrozenBalances[i] = currentFrozenBalances[currentFrozenBalances.length - 1];
                currentFrozenBalances.length --;
                i--;
            }          
        }        
        return frozenAmount;
    }
}