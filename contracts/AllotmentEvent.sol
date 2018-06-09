pragma solidity ^ 0.4.24;

import "./Owned.sol";

contract AllotmentEvent is Owned {

    uint public eventId;

    constructor(uint _eventId) public {
        eventId = _eventId;
    }
}