pragma solidity ^ 0.4.24;

contract FreezableTokenTarget {
    function frozen(address _sender, uint256 _amount) external;

    function getFreezingDuration() external view returns(uint);
}