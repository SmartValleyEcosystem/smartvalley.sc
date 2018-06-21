pragma solidity ^ 0.4.24;

import "./Owned.sol";
import "./AdministratorsRegistry.sol";
import "./AllotmentEvent.sol";

contract AllotmentEventsManager is Owned {

    AdministratorsRegistry public administratorsRegistry;

    mapping(uint => address) allotmentEventsMap;
    address public returnAddress;

    constructor(address _administratorsRegistryAddress) public {
        setAdministratorsRegistry(_administratorsRegistryAddress);
    }

    modifier onlyAdministrators {
        require(administratorsRegistry.isAdministrator(msg.sender));
        _;
    }

    function create(uint _eventId, string _name, uint _tokenDecimals, string _tokenTicker, address _tokenContractAddress, uint _finishTimestamp) external onlyAdministrators {
        require(allotmentEventsMap[_eventId] == 0);

        AllotmentEvent allotmentEvent = new AllotmentEvent(_eventId, _name, _tokenDecimals, _tokenTicker, _tokenContractAddress, _finishTimestamp, address(this));
        allotmentEventsMap[_eventId] = address(allotmentEvent);
    }

    function start(uint _eventId) external onlyAdministrators {
        require(allotmentEventsMap[_eventId] != 0);

        AllotmentEvent(allotmentEventsMap[_eventId]).start();
    }

    function edit(uint _eventId, string _name, uint _tokenDecimals, string _tokenTicker, address _tokenContractAddress, uint _finishTimestamp) external onlyAdministrators {
        require(allotmentEventsMap[_eventId] != 0);

        AllotmentEvent(allotmentEventsMap[_eventId]).edit(_name, _tokenDecimals, _tokenTicker, _tokenContractAddress, _finishTimestamp);
    }

    function getAllotmentEventContractAddress(uint _eventId) external view returns(address) {
        return allotmentEventsMap[_eventId];
    }

    function setAdministratorsRegistry(address _address) public onlyOwner {
        require(_address != 0);
        administratorsRegistry = AdministratorsRegistry(_address);
    }

    function setReturnAddress(address _value) public onlyOwner {
        require(_value != 0);
        returnAddress = _value;
    }
}