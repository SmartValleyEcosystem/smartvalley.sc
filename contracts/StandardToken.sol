pragma solidity ^ 0.4.22;

import "./Owned.sol";
import "./ERC20Interface.sol";

contract StandardToken is Owned, ERC20 {

    mapping(address => uint) internal balances;
    mapping(address => mapping(address => uint)) public allowed;

    constructor() public {}

    function transferInternal(address _from, address _to, uint _value) internal {
        require(balances[_from] >= _value);
        require(balances[_to] + _value >= balances[_to]); // overflow
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function balanceOf(address who) public constant returns(uint) {
        return balances[who];
    }

    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
       transferInternal(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
        require(balances[_from] >= _value);
        require(balances[_to] + _value >= balances[_to]); // overflow
        require(allowed[_from][msg.sender] >= _value);
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value) public {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public constant returns(uint remaining) {
        return allowed[_owner][_spender];
    }

    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }
}