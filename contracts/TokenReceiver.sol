pragma solidity ^ 0.4.24;

contract TokenReceiver {
    function tokenFallback(address _from, uint256 _value, bytes _data) external;
}