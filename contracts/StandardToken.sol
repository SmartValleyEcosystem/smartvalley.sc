pragma solidity ^ 0.4.24;

import "./Owned.sol";
import "./ERC223.sol";
import "./SafeMath.sol";
import "./ContractExtensions.sol";
import "./TokenReceiver.sol";

contract StandardToken is Owned, ERC223 {

    using SafeMath for uint;
    using ContractExtensions for address;

    mapping(address => uint) balances;

    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns(uint) {
        return balances[_owner];
    }

    function transfer(address _to, uint _value, bytes _data, string _customFallback) public returns(bool) {
        transferInternal(_to, _value, _data);

        if(_to.isContract()) {
            assert(_to.call.value(0)(bytes4(keccak256(_customFallback)), msg.sender, _value, _data));
        }

        return true;
    }

    function transfer(address _to, uint _value, bytes _data) public returns(bool) {
        transferInternal(_to, _value, _data);

        if(_to.isContract()) {
            TokenReceiver receiver = TokenReceiver(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }

        return true;
    }

    function transfer(address _to, uint _value) public returns(bool) {
        return transfer(_to, _value, new bytes(0));
    }

    function transferInternal(address _to, uint _value, bytes _data) private {
        require(hasEnoughTokens(msg.sender, _value));

        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);

        emit Transfer(msg.sender, _to, _value, _data);
    }

    function hasEnoughTokens(address _from, uint _value) private view returns(bool) {
        return balanceOf(_from) >= _value;
    }
}