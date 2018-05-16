pragma solidity ^ 0.4.23;

import "./Owned.sol";

contract ScoringsRegistry is Owned {

    struct AreaScoring {
        uint requiredExpertsCount;
        address[] offers;
        mapping(address => uint) offerStates;
        mapping(address => uint) scoringDeadlines;
    }

    struct Scoring {
        address contractAddress;
        uint[] areas;
        uint pendingOffersExpirationTimestamp;
        mapping(uint => AreaScoring) areaScorings;
    }

    uint[] public projectIds;
    mapping(uint => Scoring) public scoringsMap;

    address public scoringExpertsManagerAddress;
    address public scoringManagerAddress;
    address public migrationHostAddress;

    modifier onlyScroingExpertsManager {
        require(scoringExpertsManagerAddress == msg.sender);
        _;
    }

    modifier onlyScoringManager {
        require(scoringManagerAddress == msg.sender);
        _;
    }

    function setScoringExpertsManager(address _address) external onlyOwner {
        require(_address != 0);
        scoringExpertsManagerAddress = _address;
    }

    function setScoringManager(address _address) external onlyOwner {
        require(_address != 0);
        scoringManagerAddress = _address;
    }

    function setMigrationHost(address _address) external onlyOwner {
        require(_address != 0);
        migrationHostAddress = _address;
    }

    function getScoringsCount() public view returns (uint) {
        return projectIds.length;
    }

    function getScoringAddressByIndex(uint _index) public view returns (address) {
        return getScoringAddressById(projectIds[_index]);
    }

    function getProjectIdByIndex(uint _index) public view returns (uint) {
        return projectIds[_index];
    }

    function getScoringAddressById(uint _projectId) public view returns (address) {
        return scoringsMap[_projectId].contractAddress;
    }

    function getScoringAreas(uint _projectId) public view returns (uint[]) {
        return scoringsMap[_projectId].areas;
    }

    function addScoring(address _scoringAddress, uint _projectId, uint[] _areas, uint[] _areaExpertCounts, uint _pendingOffersExpirationTimestamp) external onlyScoringManager {
        addScoringInternal(_scoringAddress, _projectId, _areas, _areaExpertCounts, _pendingOffersExpirationTimestamp);
    }

    function getOffers(uint _projectId, uint _area) public view returns (address[]) {
        return scoringsMap[_projectId].areaScorings[_area].offers;
    }

    function addOffer(uint _projectId, uint _area, address _expert, uint _state, uint _deadline) external onlyScroingExpertsManager {
        addOfferInternal(_projectId, _area, _expert, _state, _deadline);
    }

    function getOfferState(uint _projectId, uint _area, address _expert) public view returns(uint) {
        return scoringsMap[_projectId].areaScorings[_area].offerStates[_expert];
    }

    function setOfferState(uint _projectId, uint _area, address _expert, uint _state) external onlyScroingExpertsManager {
        setOfferStateInternal(_projectId,_area, _expert, _state);
    }

    function getScoringDeadline(uint _projectId, uint _area, address _expert) public view returns(uint) {
        return scoringsMap[_projectId].areaScorings[_area].scoringDeadlines[_expert];
    }

    function setScoringDeadline(uint _projectId, uint _area, address _expert, uint _deadline) external onlyScroingExpertsManager {
        setScoringDeadlineInternal(_projectId,_area, _expert, _deadline);
    }

    function getPendingOffersExpirationTimestamp(uint _projectId) external view returns(uint) {
        return scoringsMap[_projectId].pendingOffersExpirationTimestamp;
    }

    function setPendingOffersExpirationTimestamp(uint _projectId, uint _timestamp) external onlyScroingExpertsManager {
        scoringsMap[_projectId].pendingOffersExpirationTimestamp = _timestamp;
    }

    function getRequiredExpertsCount(uint _projectId, uint _area) public view returns (uint) {
        return scoringsMap[_projectId].areaScorings[_area].requiredExpertsCount;
    }

    function migrateFromHost(uint _startIndex, uint _count) external onlyOwner {
        require(migrationHostAddress != 0, "migration host was not set");

        ScoringsRegistry scoringRegistry = ScoringsRegistry(migrationHostAddress);

        require(_startIndex + _count <= scoringRegistry.getScoringsCount());

        for (uint i = _startIndex; i < _startIndex + _count; i++) {
            uint projectId = scoringRegistry.getProjectIdByIndex(i);
            uint[] memory areas = scoringRegistry.getScoringAreas(projectId);

            addScoringInternal(
                scoringRegistry.getScoringAddressByIndex(i),
                projectId,
                areas,
                new uint[](areas.length),
                scoringRegistry.getPendingOffersExpirationTimestamp(projectId));

            for (uint areaIndex = 0; areaIndex < areas.length; areaIndex++) {
                uint area = areas[areaIndex];

                setRequiredExpertsCount(projectId, area, scoringRegistry.getRequiredExpertsCount(projectId, area));

                address[] memory offers = scoringRegistry.getOffers(projectId, area);
                for (uint offerIndex = 0; offerIndex < offers.length; offerIndex++) {
                    uint state = scoringRegistry.getOfferState(projectId, area, offers[offerIndex]);
                    uint deadline = scoringRegistry.getScoringDeadline(projectId, area, offers[offerIndex]);
                    addOfferInternal(projectId, area, offers[offerIndex], state, deadline);
                }
            }
        }
    }

    function addScoringInternal(address _scoringAddress, uint _projectId, uint[] _areas, uint[] _areaExpertCounts, uint _pendingOffersExpirationTimestamp) private {
        projectIds.push(_projectId);
        scoringsMap[_projectId] = Scoring(_scoringAddress, _areas, _pendingOffersExpirationTimestamp);

        for (uint i = 0; i < _areas.length; i++) {
            scoringsMap[_projectId].areaScorings[_areas[i]] = AreaScoring(_areaExpertCounts[i], new address[](0));
        }
    }

    function addOfferInternal(uint _projectId, uint _area, address _expert, uint _state, uint _deadline) private {
        scoringsMap[_projectId].areaScorings[_area].offers.push(_expert);

        setOfferStateInternal(_projectId, _area, _expert, _state);
        setScoringDeadlineInternal(_projectId, _area, _expert, _deadline);
    }

    function setOfferStateInternal(uint _projectId, uint _area, address _expert, uint _state) private {
        if (scoringsMap[_projectId].areaScorings[_area].offerStates[_expert] != _state)
            scoringsMap[_projectId].areaScorings[_area].offerStates[_expert] = _state;
    }

    function setScoringDeadlineInternal(uint _projectId, uint _area, address _expert, uint _deadline) private {
        if (scoringsMap[_projectId].areaScorings[_area].scoringDeadlines[_expert] != _deadline)
            scoringsMap[_projectId].areaScorings[_area].scoringDeadlines[_expert] = _deadline;
    }

    function setRequiredExpertsCount(uint _projectId, uint _area, uint count) private {
        scoringsMap[_projectId].areaScorings[_area].requiredExpertsCount = count;
    }
}