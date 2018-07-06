pragma solidity ^ 0.4.24;

import "./FreezableToken.sol";
import "./TokenReceiver.sol";
import "./MigrationAgent.sol";

contract SmartValleyToken is FreezableToken, MigrationAgent {

    address public minter;
    address public burner;

    string public name = "Smart Valley";
    string public symbol = "SVT";
    uint8 public decimals = 18;

    mapping(address => bool) public migratedAddresses;

    bool public isTransferAllowed = false;
    bool public isMintingAllowed = true;

    modifier onlyMinter {
        require(msg.sender == minter);
        _;
    }

    modifier onlyBurner {
        require(msg.sender == burner);
        _;
    }

    modifier whileMintingAllowed {
        require(isMintingAllowed == true);
        _;
    }

    modifier whenTransferAllowed {
        require(isTransferAllowed == true);
        _;
    }

    function setMinter(address _minter) public onlyOwner whileMintingAllowed {
        minter = _minter;
    }
    
    function setBurner(address _burner) public onlyOwner {
        burner = _burner;
    }

    function transfer(address _to, uint _value, bytes _data, string _customFallback) public whenTransferAllowed returns(bool) {
        super.transfer(_to, _value, _data, _customFallback);
    }

    function transfer(address _to, uint _value, bytes _data) public whenTransferAllowed returns(bool) {
        super.transfer(_to, _value, _data);
    }

    function transfer(address _to, uint _value) public whenTransferAllowed returns(bool) {
        super.transfer(_to, _value);
    }

    function mint(address _to, uint _amount) public onlyMinter {
        require(_amount > 0);

        balances[_to] = balances[_to].add(_amount);
        totalSupply = totalSupply.add(_amount);

        emit Transfer(address(this), _to, _amount, new bytes(0));
    }

    function burn(address _from, uint _amount) public onlyBurner {
        require(_amount > 0);
        require(balances[_from] >= _amount);

        balances[_from] = balances[_from].sub(_amount);
        totalSupply = totalSupply.sub(_amount);

        emit Transfer(_from, 0x0, _amount, new bytes(0));
    }

    function blockMinting() onlyOwner public {
        delete minter;

        isTransferAllowed = true;
        isMintingAllowed = false;
    }

    function migrateFrom(address _tokenHolder, uint _value) public onlyMinter {
        require(migratedAddresses[_tokenHolder] == false);

        mint(_tokenHolder, _value);
        migratedAddresses[_tokenHolder] = true;
    }

    function hasEnoughTokens(address _from, uint _value) private view returns(bool) {
        return getAvailableBalance(_from) >= _value;
    }
}