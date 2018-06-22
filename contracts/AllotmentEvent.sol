pragma solidity ^ 0.4.24;

import "./Owned.sol";
import "./TokenInterface.sol";
import "./FreezableTokenTarget.sol";
import "./SafeMath.sol";
import "./ContractExtensions.sol";
import "./AllotmentEventsManager.sol";

contract AllotmentEvent is Owned, FreezableTokenTarget {

    using SafeMath for uint;
    using ContractExtensions for address;

    enum Status {
        Published,
        InProgress,
        Finished
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

    mapping(address => uint) public participantBids;
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

    function getInfo() external view returns(string _name, uint _status, uint _tokenDecimals, string _tokenTicker, address _tokenContractAddress, uint _startTimestamp, uint _finishTimestamp) {
        _name = name;
        _status = uint(status);
        _tokenDecimals = tokenDecimals;
        _tokenTicker = tokenTicker;
        _tokenContractAddress = address(token);
        _startTimestamp = startTimestamp;
        _finishTimestamp = finishTimestamp;
    }

    function getResults() external view returns(uint _totalTokensToDistribute, uint _totalBidsAmount, address[] _participants, uint[] _participantBids, uint[] _participantShares) {
        require(status == Status.InProgress || status == Status.Finished);

        _totalTokensToDistribute = token.balanceOf(address(this));
        _participants = participants;
        _participantBids = new uint[](participants.length);
        _participantShares = new uint[](participants.length);

        for (uint i = 0; i < participants.length; i++) {
            _participantBids[i] = participantBids[participants[i]];
            _totalBidsAmount = _totalBidsAmount.add(_participantBids[i]);
        }

        for (uint j = 0; j < participants.length; j++) {
            _participantShares[j] = _totalTokensToDistribute.multiply(_participantBids[j]) / _totalBidsAmount;
        }
    }

    function frozen(address _sender, uint256 _amount, bytes _data) external {
        registerBid(_sender, _amount);
    }

    function getFreezingDuration() external returns(uint) {
        return freezingDuration;
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

        startTimestamp = _value;
    }

    function setFinishTimestamp(uint _value) private {
        require(_value == 0 || _value > startTimestamp);

        finishTimestamp = _value;
    }

    function setTokenContractAddress(address _value) private {
        require(status != Status.Finished);
        require(_value.isContract());

        token = TokenInterface(_value);
    }

    function getReturnAddress() private view returns(address) {
        return manager.returnAddress();
    }
}