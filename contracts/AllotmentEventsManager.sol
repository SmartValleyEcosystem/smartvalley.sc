pragma solidity ^ 0.4.24;

import "./Owned.sol";
import "./AdministratorsRegistry.sol";
import "./AllotmentEvent.sol";

contract AllotmentEventsManager is Owned {

    AdministratorsRegistry public administratorsRegistry;

    mapping(uint => address) allotmentEventsMap;

    constructor(address _administratorsRegistryAddress) public {
        setAdministratorsRegistry(_administratorsRegistryAddress);
    }

    modifier onlyAdministrators {
        require(administratorsRegistry.isAdministrator(msg.sender));
        _;
    }

    function create(uint _eventId) external onlyAdministrators {
        require(allotmentEventsMap[_eventId] == 0);

        AllotmentEvent allotmentEvent = new AllotmentEvent(_eventId);
        allotmentEventsMap[_eventId] = address(allotmentEvent);
    }

    function start(uint _eventId, address _tokenContractAddress, uint _startTimestamp, uint _finishTimestamp) external onlyAdministrators {
        require(allotmentEventsMap[_eventId] != 0);

        AllotmentEvent(allotmentEventsMap[_eventId]).start(_tokenContractAddress, _startTimestamp, _finishTimestamp);
    }

    function edit(uint _eventId, address _tokenContractAddress, uint _finishTimestamp) external onlyAdministrators {
        require(allotmentEventsMap[_eventId] != 0);

        AllotmentEvent(allotmentEventsMap[_eventId]).edit(_tokenContractAddress, _finishTimestamp);
    }

    function getAllotmentEventContractAddress(uint _eventId) external view returns(address) {
        return allotmentEventsMap[_eventId];
    }

    function setAdministratorsRegistry(address _address) public onlyOwner {
        require(_address != 0);
        administratorsRegistry = AdministratorsRegistry(_address);
    }
}