pragma solidity ^ 0.4.24;

import "./Owned.sol";
import "./AdministratorsRegistry.sol";
import "./AllotmentEvent.sol";

contract AllotmentEventsManager is Owned {

    AdministratorsRegistry public administratorsRegistry;

    mapping(uint => address) public allotmentEventsMap;
    uint public freezingDuration;
    address public returnAddress;

    constructor(address _administratorsRegistryAddress, uint _freezingDuration) public {
        setFreezingDuration(_freezingDuration);
        setAdministratorsRegistry(_administratorsRegistryAddress);
    }

    modifier onlyAdministrators {
        require(administratorsRegistry.isAdministrator(msg.sender));
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

    function getAllotmentEventContractAddress(uint _eventId) external view returns(address) {
        return allotmentEventsMap[_eventId];
    }

    function setAdministratorsRegistry(address _address) public onlyOwner {
        require(_address != 0);
        administratorsRegistry = AdministratorsRegistry(_address);
    }

    function setFreezingDuration(uint _value) public onlyOwner {
        require(_value != 0);
        freezingDuration = _value;
    }

    function setReturnAddress(address _value) public onlyOwner {
        require(_value != 0);
        returnAddress = _value;
    }
}