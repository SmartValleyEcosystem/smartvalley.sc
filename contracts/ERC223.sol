pragma solidity ^ 0.4.24;

contract ERC223 {
    uint public totalSupply;

    string public name;
    string public symbol;
    uint8 public decimals;

    function balanceOf(address _owner) public view returns (uint);

    function transfer(address _to, uint _value) public returns(bool);
    function transfer(address _to, uint _value, bytes _data) public returns(bool);
    function transfer(address _to, uint _value, bytes _data, string _customFallback) public returns(bool);

    event Transfer(address indexed _from, address indexed _to, uint _value, bytes _data);
}