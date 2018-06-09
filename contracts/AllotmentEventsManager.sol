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

    function getAllotmentEventContractAddress(uint _eventId) external view returns(address) {
        return allotmentEventsMap[_eventId];
    }

    function setAdministratorsRegistry(address _address) public onlyOwner {
        require(_address != 0);
        administratorsRegistry = AdministratorsRegistry(_address);
    }
}