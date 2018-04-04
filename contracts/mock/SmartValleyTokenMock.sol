pragma solidity ^ 0.4.18;

import "../SmartValleyToken.sol";

contract SmartValleyTokenMock is SmartValleyToken {
    function SmartValleyTokenMock(address _freezer, address[] _accounts, uint256 _initialbalance) SmartValleyToken(_freezer) public {
        for (uint i = 0; i < _accounts.length; i++) {
            balances[_accounts[i]] = _initialbalance;
            totalSupply += _initialbalance;
        }
    }
}