pragma solidity ^ 0.4.18;

import "./StandardToken.sol";
import "./MigrationAgentInterface.sol";
import "./KnownContractInterface.sol";

contract SmartValleyToken is StandardToken, MigrationAgent {

    string public constant symbol = "SVT";
    string public constant name = "Smart Valley";
    uint8 public constant decimals = 18;

    address public minter;
    address public burner;
    
    mapping(address => bool) public migratedAddresses;
    mapping(address => bool) public knownContracts;
    
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
    
    modifier onlyKnownContracts(address _address) {
        require(knownContracts[_address] == true);
        _;
    }   

    function setMinter(address _minter) public onlyOwner whileMintingAllowed {
        minter = _minter;
    }
    
    function setBurner(address _burner) public onlyOwner {
        burner = _burner;
    }
    
    function mintTokens(address _to, uint256 _tokensAmountWithDecimals) public onlyMinter {
        require(_tokensAmountWithDecimals > 0);
        
        balances[_to] += _tokensAmountWithDecimals;
        totalSupply += _tokensAmountWithDecimals;
        
        Transfer(this, _to, _tokensAmountWithDecimals);
    }
    
    function burnTokens(address _from, uint _tokensAmountWithDecimals) public onlyBurner {
        require(_tokensAmountWithDecimals > 0);
        require(balances[_from] >= _tokensAmountWithDecimals);
        
        balances[_from] -= _tokensAmountWithDecimals;
        totalSupply -= _tokensAmountWithDecimals;
        
        Transfer(_from, 0x0, _tokensAmountWithDecimals);
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
    
    function transfer(address _to, uint _value) public whenTransferAllowed {
        super.transfer(_to, _value);
        
        if (knownContracts[_to] == true) {
            var knownContract = KnownContract(_to);
            knownContract.transfered(msg.sender, _value, new bytes32[](0));
        }
    }
    
    function transferFrom(address _from, address _to, uint _value) public whenTransferAllowed {
        super.transferFrom(_from, _to, _value);

        if (knownContracts[_to] == true) {
            var knownContract = KnownContract(_to);
            knownContract.transfered(_from, _value, new bytes32[](0));
        }
    }

    function transferFromOrigin(address _to, uint _value) external onlyKnownContracts(msg.sender) {
        transferInternal(tx.origin, _to, _value);
    }
    
    function addKnownContract(address _address) external onlyOwner {
        knownContracts[_address] = true;
    }  

    function removeKnownContract(address _address) external onlyOwner {
        delete knownContracts[_address];
    }

    function transferToKnownContract(address _to, uint256 _value, bytes32[] _data) external whenTransferAllowed onlyKnownContracts(_to) {
        var knownContract = KnownContract(_to);
        super.transfer(_to, _value);
        knownContract.transfered(msg.sender, _value, _data);
    }
}