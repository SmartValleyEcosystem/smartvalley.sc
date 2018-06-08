pragma solidity ^ 0.4.24;

contract ERC223 {
    uint public totalSupply;

    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint);
    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);

    function transfer(address _to, uint _value) public returns(bool);
    function transfer(address _to, uint _value, bytes _data) public returns(bool);
    function transfer(address _to, uint _value, bytes _data, string _customFallback) public returns(bool);

    event Transfer(address indexed _from, address indexed _to, uint _value, bytes indexed _data);
}