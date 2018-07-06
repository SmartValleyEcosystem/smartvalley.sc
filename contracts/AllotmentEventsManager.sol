pragma solidity ^ 0.4.24;

import "./Owned.sol";
import "./AdministratorsRegistry.sol";
import "./AllotmentEvent.sol";
import "./ArrayExtensions.sol";

contract AllotmentEventsManager is Owned {

    using ArrayExtensions for address[];

    mapping(uint => address) public allotmentEventsMap;
    address[] public allotmentEvents;
    uint public freezingDuration;
    address public returnAddress;
    address public smartValleyTokenAddress;
    AdministratorsRegistry public administratorsRegistry;

    constructor(
        address _administratorsRegistryAddress,
        uint _freezingDurationDays,
        address _smartValleyTokenAddress) public {

        setFreezingDuration(_freezingDurationDays);
        setAdministratorsRegistry(_administratorsRegistryAddress);
        setSmartValleyTokenAddress(_smartValleyTokenAddress);
    }

    modifier onlyAdministrators {
        require(msg.sender == owner || administratorsRegistry.isAdministrator(msg.sender));
        _;
    }

    function create(
        uint _eventId,
        string _name,
        uint _tokenDecimals,
        string _tokenTicker,
        address _tokenContractAddress,
        uint _finishTimestamp) external onlyAdministrators {

        require(allotmentEventsMap[_eventId] == 0);

        AllotmentEvent allotmentEvent = new AllotmentEvent(
            _eventId,
            _name,
            _tokenDecimals,
            _tokenTicker,
            _tokenContractAddress,
            _finishTimestamp,
            freezingDuration,
            address(this));

        allotmentEventsMap[_eventId] = address(allotmentEvent);
        allotmentEvents.push(address(allotmentEvent));
    }

    function start(uint _eventId) external onlyAdministrators {
        require(allotmentEventsMap[_eventId] != 0);

        AllotmentEvent(allotmentEventsMap[_eventId]).start();
    }

    function edit(
        uint _eventId,
        string _name,
        uint _tokenDecimals,
        string _tokenTicker,
        address _tokenContractAddress,
        uint _finishTimestamp) external onlyAdministrators {

        require(allotmentEventsMap[_eventId] != 0);

        AllotmentEvent(allotmentEventsMap[_eventId]).edit(_name, _tokenDecimals, _tokenTicker, _tokenContractAddress, _finishTimestamp);
    }

    function returnBids(uint _eventId) external onlyAdministrators {
        require(allotmentEventsMap[_eventId] != 0);

        AllotmentEvent(allotmentEventsMap[_eventId]).returnBids();
    }

    function remove(uint _eventId) external onlyAdministrators {
        require(allotmentEventsMap[_eventId] != 0);

        AllotmentEvent(allotmentEventsMap[_eventId]).destruct();

        allotmentEvents.remove(allotmentEventsMap[_eventId]);
        delete allotmentEventsMap[_eventId];
    }

    function getAllotmentEventContractAddress(uint _eventId) external view returns(address) {
        return allotmentEventsMap[_eventId];
    }

    function getFreezingDurationDays() external view returns(uint) {
        return freezingDuration / 1 days;
    }

    function setAdministratorsRegistry(address _address) public onlyOwner {
        require(_address != 0);
        administratorsRegistry = AdministratorsRegistry(_address);
    }

    function setSmartValleyTokenAddress(address _address) public onlyOwner {
        require(_address != 0);
        smartValleyTokenAddress = _address;
    }

    function setFreezingDuration(uint _days) public onlyAdministrators {
        require(_days != 0);
        freezingDuration = _days * 1 days;
    }

    function setReturnAddress(address _value) public onlyAdministrators {
        require(_value != 0);
        returnAddress = _value;
    }
}