pragma solidity ^ 0.4.24;

import "./Owned.sol";
import "./TokenInterface.sol";
import "./FreezableTokenTarget.sol";
import "./SmartValleyToken.sol";
import "./SafeMath.sol";
import "./ContractExtensions.sol";
import "./AllotmentEventsManager.sol";

contract AllotmentEvent is Owned, FreezableTokenTarget {

    using SafeMath for uint;
    using ContractExtensions for address;

    enum Status {
        Published,
        InProgress,
        Finished,
        Destruction
    }

    uint public eventId;
    string public name;
    uint public tokenDecimals;
    string public tokenTicker;
    Status public status;
    TokenInterface public token;
    AllotmentEventsManager public manager;
    uint public startTimestamp;
    uint public finishTimestamp;
    uint public freezingDuration;
    uint public tokensToDistribute;

    mapping(address => uint) public participantBids;
    mapping(address => bool) public collectedSharesMap;
    address[] public participants;

    constructor(
        uint _eventId,
        string _name,
        uint _tokenDecimals,
        string _tokenTicker,
        address _tokenContractAddress,
        uint _finishTimestamp,
        uint _freezingDuration,
        address _managerAddress) public {

        require(_eventId != 0);

        eventId = _eventId;
        name = _name;
        tokenDecimals = _tokenDecimals;
        tokenTicker = _tokenTicker;
        freezingDuration = _freezingDuration;
        manager = AllotmentEventsManager(_managerAddress);
        setTokenContractAddress(_tokenContractAddress);
        setFinishTimestamp(_finishTimestamp);
    }

    modifier onlySmartValleyToken {
        require(msg.sender == manager.smartValleyTokenAddress());
        _;
    }

    function start() external onlyOwner {
        require(status == Status.Published);
        require(token.balanceOf(address(this)) > 0);

        status = Status.InProgress;

        setStartTimestamp(now);
    }

    function edit(
        string _name,
        uint _tokenDecimals,
        string _tokenTicker,
        address _tokenContractAddress,
        uint _finishTimestamp) external onlyOwner {

        name = _name;
        tokenDecimals = _tokenDecimals;
        tokenTicker = _tokenTicker;

        setTokenContractAddress(_tokenContractAddress);
        setFinishTimestamp(_finishTimestamp);
    }

    function frozen(address _sender, uint256 _amount) external onlySmartValleyToken {
        registerBid(_sender, _amount);
    }

    function collectTokens() external {
        require(finishTimestamp > 0 && now > finishTimestamp);
        require(status == Status.InProgress || status == Status.Finished);
        require(participantBids[msg.sender] > 0);
        require(!collectedSharesMap[msg.sender]);

        if (status != Status.Finished) {
            status = Status.Finished;
            tokensToDistribute = token.balanceOf(address(this));
        }

        uint totalBidsAmount = getTotalBidsAmount();
        uint share = getTokensToDistribute().multiply(participantBids[msg.sender]) / totalBidsAmount;

        token.transfer(msg.sender, share);
        collectedSharesMap[msg.sender] = true;
    }

    function destruct() external onlyOwner {
        assert(!hasBids());

        address returnAddress = manager.returnAddress();
        assert(returnAddress != 0);

        uint tokenBalance = token.balanceOf(address(this));
        token.transfer(returnAddress, tokenBalance);

        selfdestruct(returnAddress);
    }

    function returnBids() external onlyOwner {
        if (status != Status.Destruction)
            status = Status.Destruction;

        uint iterationCost = 0;
        for (uint i = 0; i < participants.length; i++) {
            uint currentGasLeft = gasleft();
            if (iterationCost > 0 && currentGasLeft < iterationCost * 2)
                return;

            address participant = participants[i];
            if (participantBids[participant] > 0) {
                SmartValleyToken(manager.smartValleyTokenAddress()).unfreeze(participant);
                delete participantBids[participant];

                if (iterationCost == 0) {
                    iterationCost = currentGasLeft - gasleft();
                }
            }
        }
    }

    function getFreezingDuration() external view returns(uint) {
        return freezingDuration;
    }

    function hasBids() public view returns(bool) {
        if (participants.length == 0)
            return false;

        for (uint i = 0; i < participants.length; i++) {
            if (participantBids[participants[i]] > 0)
                return true;
        }

        return false;
    }

    function getInfo() external view returns(string _name, uint _status, uint _tokenDecimals, string _tokenTicker, address _tokenContractAddress, uint _startTimestamp, uint _finishTimestamp) {
        _name = name;
        _status = uint(status);
        _tokenDecimals = tokenDecimals;
        _tokenTicker = tokenTicker;
        _tokenContractAddress = address(token);
        _startTimestamp = startTimestamp;
        _finishTimestamp = finishTimestamp;
    }

    function getResults() external view returns(uint _totalTokensToDistribute, uint _totalBidsAmount, address[] _participants, uint[] _participantBids, uint[] _participantShares, bool[] _collectedShares) {
        _totalTokensToDistribute = getTokensToDistribute();
        _totalBidsAmount = getTotalBidsAmount();
        _participants = participants;
        _participantBids = new uint[](participants.length);
        _participantShares = new uint[](participants.length);
        _collectedShares = new bool[](participants.length);

        for (uint i = 0; i < participants.length; i++) {
            _participantBids[i] = participantBids[participants[i]];
            _collectedShares[i] = collectedSharesMap[participants[i]];
            _participantShares[i] = _totalBidsAmount == 0 ? 0 : _totalTokensToDistribute.multiply(_participantBids[i]) / _totalBidsAmount;
        }
    }

    function getTotalBidsAmount() private view returns(uint _result) {
        for (uint i = 0; i < participants.length; i++) {
            _result = _result.add(participantBids[participants[i]]);
        }
    }

    function getTokensToDistribute() private view returns(uint) {
        return tokensToDistribute == 0 ? token.balanceOf(address(this)) : tokensToDistribute;
    }

    function registerBid(address _account, uint _amount) private {
        require(_amount > 0 && _account != 0);

        if (participantBids[_account] == 0) {
            participants.push(_account);
        }

        participantBids[_account] = participantBids[_account].add(_amount);
    }

    function setStartTimestamp(uint _value) private {
        require(finishTimestamp > _value);
        require(finishTimestamp < _value + freezingDuration);

        startTimestamp = _value;
    }

    function setFinishTimestamp(uint _value) private {
        require(_value == 0 || _value > startTimestamp);
        require(startTimestamp == 0 || _value < startTimestamp + freezingDuration);

        finishTimestamp = _value;
    }

    function setTokenContractAddress(address _value) private {
        require(status != Status.Finished);
        require(_value.isContract());

        token = TokenInterface(_value);
    }
}