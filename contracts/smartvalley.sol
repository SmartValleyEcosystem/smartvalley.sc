pragma solidity ^ 0.4.13;

contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value);
}

contract Owned {

    address public owner;
    address public newOwner;
    address public oracle; 

    function Owned() payable {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    modifier onlyOwnerOrOracle {
        require(owner == msg.sender || oracle == msg.sender);
        _;
    }
   
    function changeOwner(address _owner) onlyOwner external {
        require(_owner != 0);
        newOwner = _owner;
    }

    function confirmOwner() external {
        require(newOwner == msg.sender);
        owner = newOwner;
        delete newOwner;
    }

    function changeOracle(address _oracle) onlyOwner external {
        require(_oracle != 0);
        oracle = _oracle;
    }  
}

contract ERC20 {
    uint public totalSupply;

    function balanceOf(address who) constant returns(uint);

    function transfer(address to, uint value);

    function allowance(address owner, address spender) constant returns(uint);

    function transferFrom(address from, address to, uint value);

    function approve(address spender, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}

contract Stateful {
    enum State {
        Initial,
        PrivateSale,       
        SaleFinished
    }
    State public state = State.Initial;

    event StateChanged(State oldState, State newState);

    function setState(State newState) internal {
        State oldState = state;
        state = newState;
        StateChanged(oldState, newState);
    }
}

contract Crowdsale is Owned, Stateful {

    uint public etherPriceUSDWEI;
    address public beneficiary;
    uint constant tokenPriceUSDWEI = 100000000000000000; 

    struct Investor {
        uint amountTokens;     
        uint index; 
    }

    mapping(address => Investor) public investors;
    address[] public investorIndex; 

    function Crowdsale() payable Owned() {}

    //abstract methods
    function emitTokens(address _investor, uint _usdwei) internal returns(uint tokensToEmit);   

    function burnTokens(address _address, uint _amount) internal; 
  
    function isInvestor(address _address) public constant returns(bool isIndeed) {
        if (investorIndex.length == 0) {
             return false;
        }
        return (investorIndex[investors[_address].index] == _address);
    }

    function insertInvestor(address _address, uint _amountTokens) internal returns(uint index) {           
        investors[_address].amountTokens = _amountTokens;       
        investors[_address].index = investorIndex.push(_address) - 1;       
        return investorIndex.length - 1;
    }

    function updateInvestorTokens(address _address, uint _amountTokens) internal returns(bool success) {     
        investors[_address].amountTokens += _amountTokens;  
        return true;
    }

    function deleteInvestor(address _address) internal returns(uint index) {        
        uint rowToDelete = investors[_address].index;
        burnTokens(_address, investors[_address].amountTokens);
        address keyToMove = investorIndex[investorIndex.length-1];
        investorIndex[rowToDelete] = keyToMove;
        investors[keyToMove].index = rowToDelete; 
        investorIndex.length--;    
        return rowToDelete;
    }

    function depositUSD(address _to, uint _amountUSDWEI, uint _bonusPercentWEI) public onlyOwner crowdsaleState {     
        if (_bonusPercentWEI != 0) {
            _amountUSDWEI = (_amountUSDWEI * ( 1 ether + _bonusPercentWEI / 100)) / 1 ether;
        }       
        emitTokensFor(_to,  _amountUSDWEI);
    }

    function emitTokensFor(address _investor, uint _valueUSDWEI) internal {
        var emittedTokens = emitTokens(_investor, _valueUSDWEI);
        if (isInvestor(_investor)) {
            updateInvestorTokens(_investor, emittedTokens);
        } else {
            insertInvestor(_investor, emittedTokens);
        } 
    }    

    function startPrivateSale(address _beneficiary, uint _etherPriceUSDWEI) external onlyOwner {
        require(state == State.Initial);
        beneficiary = _beneficiary;
        etherPriceUSDWEI = _etherPriceUSDWEI;
        setState(State.PrivateSale);
    }

    function finishPrivateSale() public onlyOwner {
        require(state == State.PrivateSale);
        bool isSent = beneficiary.call.gas(3000000).value(this.balance)();
        require(isSent);      
        setState(State.SaleFinished);
    }   

    function setEtherPriceUSDWEI(uint _etherPriceUSDWEI) external onlyOwnerOrOracle {
        etherPriceUSDWEI = _etherPriceUSDWEI;
    }

    function setBeneficiary(address _beneficiary) external onlyOwner {
        require(_beneficiary != 0);
        beneficiary = _beneficiary;
    }

    function withdrawFunds(uint _value) public onlyOwner {
        if (_value == 0) {
            _value = this.balance;
        }
        bool isSent = beneficiary.call.gas(3000000).value(_value)();
        require(isSent);
    }
   

    modifier crowdsaleState {
        require(state == State.PrivateSale);
        _;
    } 

    modifier saleFinishedState {
        require(state == State.SaleFinished);
        _;
    }
}

contract Token is Crowdsale, ERC20 {

    mapping(address => uint) internal balances;
    mapping(address => mapping(address => uint)) public allowed;
    uint8 public constant decimals = 18;

    function Token() payable Crowdsale() {}

    function balanceOf(address who) constant returns(uint) {
        return balances[who];
    }

    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
        require(true == false); //disabled

        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]); // overflow
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
        require(true == false); //disabled

        require(balances[_from] >= _value);
        require(balances[_to] + _value >= balances[_to]); // overflow
        require(allowed[_from][msg.sender] >= _value);
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value) public saleFinishedState {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public constant saleFinishedState returns(uint remaining) {
        return allowed[_owner][_spender];
    }

    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }
}

contract MigratableToken is Token {

    function MigratableToken() payable Token() {}

    address public migrationAgent;
    uint public totalMigrated; 
    mapping(address => bool) migratedInvestors;

    event Migrated(address indexed from, address indexed to, uint value);

    //migration by owner
    function migrateToNewContract(address _address) public onlyOwner saleFinishedState {
        require(migrationAgent != 0 && migratedInvestors[_address] == false);
        uint value = balances[_address];
        require(value > 0);
        deleteInvestor(_address);       
        totalMigrated += value;
        MigrationAgent(migrationAgent).migrateFrom(_address, value);
        Migrated(_address, migrationAgent, value);
        migratedInvestors[_address] = true;
    }  

    function migrateAllToNewContract(uint _investorsToProcess) public onlyOwner saleFinishedState {         
        while (_investorsToProcess > 0 && investorIndex.length > 0) {
            migrateToNewContract(investorIndex[investorIndex.length - 1]);
            _investorsToProcess--;               
           }      
    }

    function setMigrationAgent(address _agent) external onlyOwner {
        require(migrationAgent == 0);
        migrationAgent = _agent;
    }
}

contract SmartValleyToken is MigratableToken {

    string public constant symbol = "SVT";
    string public constant name = "SmartValley Token";  

    function SmartValleyToken() payable MigratableToken() {}

    function emitTokens(address _investor,  uint _valueUSDWEI) internal returns(uint tokensToEmit) {
        tokensToEmit = (_valueUSDWEI * (10 ** uint(decimals))) / tokenPriceUSDWEI;
        require(balances[_investor] + tokensToEmit > balances[_investor]); // overflow
        require(tokensToEmit > 0);
        balances[_investor] += tokensToEmit;
        totalSupply += tokensToEmit;
        Transfer(this, _investor, tokensToEmit);
    }

    function burnTokens(address _address, uint _amount) internal onlyOwner {
        balances[_address] -= _amount;
        totalSupply -= _amount;
        Transfer(_address, this, _amount);
    }  
}