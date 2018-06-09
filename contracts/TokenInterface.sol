pragma solidity ^ 0.4.24;

interface TokenInterface {
    function balanceOf(address _owner) public view returns(uint);
}