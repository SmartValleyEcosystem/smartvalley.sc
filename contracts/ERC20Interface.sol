pragma solidity ^ 0.4.22;

contract ERC20 {
    uint public totalSupply;

    function balanceOf(address who) public constant returns(uint);

    function transfer(address to, uint value) public;

    function allowance(address owner, address spender) public constant returns(uint);

    function transferFrom(address from, address to, uint value) public;

    function approve(address spender, uint value) public;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}