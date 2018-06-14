pragma solidity ^ 0.4.24;

import "./Owned.sol";
import "./TokenInterface.sol";

contract AllotmentEvent is Owned {

    enum Status {
        Published,
        InProgress,
        Finished
    }

    uint public eventId;
    Status public status;
    TokenInterface public token;
    uint public startTimestamp;
    uint public finishTimestamp;

    constructor(uint _eventId) public {
        require(_eventId != 0);

        eventId = _eventId;
    }

    function start(address _tokenContractAddress, uint _startTimestamp, uint _finishTimestamp) external onlyOwner {
        require(status == Status.Published);

        status = Status.InProgress;

        setTokenContractAddress(_tokenContractAddress);
        setStartTimestamp(_startTimestamp);
        setFinishTimestamp(_finishTimestamp);
    }

    function edit(address _tokenContractAddress, uint _finishTimestamp) external onlyOwner {
        require(status == Status.InProgress);
        require(_tokenContractAddress != 0 || _finishTimestamp != 0);

        setTokenContractAddress(_tokenContractAddress);
        setFinishTimestamp(_finishTimestamp);
    }

    function setStartTimestamp(uint _value) private {
        if (_value != 0 && _value != startTimestamp) {
            require(finishTimestamp == 0 || finishTimestamp > _value);

            startTimestamp = _value;
        }
    }

    function setFinishTimestamp(uint _value) private {
        if (_value != 0 && _value != finishTimestamp) {
            require(_value > startTimestamp);

            finishTimestamp = _value;
        }
    }

    function setTokenContractAddress(address _value) private {
        if (_value != 0 && _value != address(token)) {
            token = TokenInterface(_value);

            require(token.balanceOf(address(this)) > 0);
        }
    }
}