pragma solidity ^ 0.4.24;

import "./Owned.sol";
import "./TokenInterface.sol";
import "./AllotmentEventsManager.sol";

contract AllotmentEvent is Owned {

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

    constructor(uint _eventId, string _name, uint _tokenDecimals, string _tokenTicker, address _tokenContractAddress, uint _finishTimestamp, address _managerAddress) public {
        require(_eventId != 0);

        eventId = _eventId;
        name = _name;
        tokenDecimals = _tokenDecimals;
        tokenTicker = _tokenTicker;
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

    function edit(string _name, uint _tokenDecimals, string _tokenTicker, address _tokenContractAddress, uint _finishTimestamp) external onlyOwner {
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
        require(_value != 0);
        require(isContract(_value));

        token = TokenInterface(_value);
    }

    function isContract(address _address) private view returns(bool) {
        uint codeSize;
        assembly { codeSize := extcodesize(_address) }
        return codeSize > 0;
    }

    function getReturnAddress() private view returns(address) {
        return manager.returnAddress();
    }
}