pragma solidity ^ 0.4.18;

import "../contracts/SmartValleyToken.sol";

contract SmartValleyTokenMock is SmartValleyToken {
    function SmartValleyTokenMock(address _account, uint256 _initialbalance) public {
        balances[_account] = _initialbalance;
        totalSupply = _initialbalance;
    }
}