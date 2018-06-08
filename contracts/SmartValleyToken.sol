pragma solidity ^ 0.4.24;

import "./StandardToken.sol";
import "./TokenReceiver.sol";
import "./BalanceFreezer.sol";
import "./MigrationAgent.sol";

contract SmartValleyToken is StandardToken, MigrationAgent {

    address public minter;
    address public burner;
    address public balanceFreezer;

    mapping(address => bool) public migratedAddresses;

    bool public isTransferAllowed = false;
    bool public isMintingAllowed = true;

    constructor(address _freezer) public {
        symbol = "SVT";
        name = "Smart Valley";
        decimals = 18;

        setBalanceFreezer(_freezer);
    }

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

    function setBalanceFreezer(address _balanceFreezer) public onlyOwner {
        balanceFreezer = _balanceFreezer;
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

    function mintTokens(address _to, uint256 _tokensAmountWithDecimals) public onlyMinter {
        require(_tokensAmountWithDecimals > 0);

        balances[_to] = balances[_to].add(_tokensAmountWithDecimals);
        totalSupply = totalSupply.add(_tokensAmountWithDecimals);

        emit Transfer(this, _to, _tokensAmountWithDecimals, new bytes(0));
    }

    function getAvailableBalance(address _from) public view returns(uint) {
        uint frozenBalance = BalanceFreezer(balanceFreezer).getFrozenAmount(_from);

        if (balanceOf(_from) <= frozenBalance) {
            return 0;
        }

        return balanceOf(_from) - frozenBalance;
    }

    function burnTokens(address _from, uint _tokensAmountWithDecimals) public onlyBurner {
        require(_tokensAmountWithDecimals > 0);
        require(balances[_from] >= _tokensAmountWithDecimals);

        balances[_from] = balances[_from].sub(_tokensAmountWithDecimals);
        totalSupply = totalSupply.sub(_tokensAmountWithDecimals);

        emit Transfer(_from, 0x0, _tokensAmountWithDecimals, new bytes(0));
    }

    function blockMinting() onlyOwner public {
        delete minter;

        isTransferAllowed = true;
        isMintingAllowed = false;
    }

    function migrateFrom(address _tokenHolder, uint256 _value) public onlyMinter {
        require(migratedAddresses[_tokenHolder] == false);

        mintTokens(_tokenHolder, _value);
        migratedAddresses[_tokenHolder] = true;
    }

    function hasEnoughTokens(address _from, uint _value) private view returns(bool) {
        return getAvailableBalance(_from) >= _value;
    }
}