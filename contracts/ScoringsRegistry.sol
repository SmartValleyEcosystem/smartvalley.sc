pragma solidity ^ 0.4.24;

import "./Owned.sol";
import "./Scoring.sol";

contract ScoringsRegistry is Owned {

    struct AreaScoring {
        uint requiredExpertsCount;
        address[] offers;
        mapping(address => uint) offerStates;
    }

    struct ScoringInfo {
        address contractAddress;
        uint acceptingDeadline;
        uint scoringDeadline;
        uint[] areas;
        mapping(uint => AreaScoring) areaScorings;
    }

    uint[] public projectIds;
    mapping(uint => ScoringInfo) public scoringsMap;

    address public scoringOffersManagerAddress;
    address public scoringManagerAddress;
    address public privateScoringManagerAddress;
    address public migrationHostAddress;

    modifier onlyScoringOffersManager {
        require(scoringOffersManagerAddress == msg.sender);
        _;
    }

    modifier onlyScoringManager {
        require(scoringManagerAddress == msg.sender || privateScoringManagerAddress == msg.sender);
        _;
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

    function addScoring(address _scoringAddress, uint _projectId, uint[] _areas, uint[] _areaExpertCounts) external onlyScoringManager {
        addScoringInternal(_scoringAddress, _projectId, _areas, _areaExpertCounts, 0, 0);
    }

    function getScoringAreas(uint _projectId) external view returns(uint[]) {
        return scoringsMap[_projectId].areas;
    }

    function getOffers(uint _projectId, uint _area) public view returns (address[]) {
        return scoringsMap[_projectId].areaScorings[_area].offers;
    }

    function addOffer(uint _projectId, uint _area, address _expert, uint _state) external onlyScoringOffersManager {
        addOfferInternal(_projectId, _area, _expert, _state);
    }

    function removeOffer(uint _projectId, uint _area, address _expert) external onlyScoringOffersManager {
        setOfferStateInternal(_projectId, _area, _expert, 0);

        address[] storage offers = scoringsMap[_projectId].areaScorings[_area].offers;
        for (uint i = 0; i < offers.length; i++) {
            if (offers[i] == _expert) {
                delete offers[i];

                if (i != offers.length - 1) {
                    offers[i] = offers[offers.length - 1];
                }

                offers.length--;
                return;
            }
        }
    }

    function getOfferState(uint _projectId, uint _area, address _expert) public view returns(uint) {
        return scoringsMap[_projectId].areaScorings[_area].offerStates[_expert];
    }

    function setOfferState(uint _projectId, uint _area, address _expert, uint _state) external onlyScoringOffersManager {
        setOfferStateInternal(_projectId,_area, _expert, _state);
    }

    function getScoringDeadline(uint _projectId) public view returns(uint) {
        return scoringsMap[_projectId].scoringDeadline;
    }

    function setScoringDeadline(uint _projectId, uint _deadline) external onlyScoringOffersManager {
        setScoringDeadlineInternal(_projectId, _deadline);
    }

    function getAcceptingDeadline(uint _projectId) external view returns(uint) {
        return scoringsMap[_projectId].acceptingDeadline;
    }

    function setAcceptingDeadline(uint _projectId, uint _value) external onlyScoringOffersManager {
        scoringsMap[_projectId].acceptingDeadline = _value;
    }

    function getRequiredExpertsCount(uint _projectId, uint _area) public view returns (uint) {
        return scoringsMap[_projectId].areaScorings[_area].requiredExpertsCount;
    }

    function incrementRequiredExpertsCount(uint _projectId, uint _area) external onlyScoringOffersManager {
        scoringsMap[_projectId].areaScorings[_area].requiredExpertsCount++;
    }

    function decrementRequiredExpertsCount(uint _projectId, uint _area) external onlyScoringOffersManager {
        scoringsMap[_projectId].areaScorings[_area].requiredExpertsCount--;
    }

    function migrateFromHost(uint _startIndex, uint _count) external onlyOwner {
        require(migrationHostAddress != 0, "migration host was not set");

        ScoringsRegistry migrationHost = ScoringsRegistry(migrationHostAddress);

        require(_startIndex + _count <= migrationHost.getScoringsCount());

        for (uint i = _startIndex; i < _startIndex + _count; i++) {
            uint projectId = migrationHost.getProjectIdByIndex(i);
            uint[] memory areas = migrationHost.getScoringAreas(projectId);
            addScoringInternal(
                migrationHost.getScoringAddressByIndex(i),
                projectId,
                areas,
                new uint[](areas.length),
                migrationHost.getAcceptingDeadline(projectId),
                migrationHost.getScoringDeadline(projectId));

            for (uint areaIndex = 0; areaIndex < areas.length; areaIndex++) {
                uint area = areas[areaIndex];

                setRequiredExpertsCount(projectId, area, migrationHost.getRequiredExpertsCount(projectId, area));

                address[] memory offers = migrationHost.getOffers(projectId, area);
                for (uint offerIndex = 0; offerIndex < offers.length; offerIndex++) {
                    uint state = migrationHost.getOfferState(projectId, area, offers[offerIndex]);
                    addOfferInternal(projectId, area, offers[offerIndex], state);
                }
            }
        }
    }

    function setScoringOffersManager(address _address) external onlyOwner {
        require(_address != 0);
        scoringOffersManagerAddress = _address;
    }

    function setScoringManager(address _address) external onlyOwner {
        require(_address != 0);
        scoringManagerAddress = _address;
    }

    function setPrivateScoringManager(address _address) external onlyOwner {
        require(_address != 0);
        privateScoringManagerAddress = _address;
    }

    function setMigrationHost(address _address) external onlyOwner {
        require(_address != 0);
        migrationHostAddress = _address;
    }

    function addScoringInternal(address _scoringAddress, uint _projectId, uint[] _areas, uint[] _areaExpertCounts, uint _acceptingDeadline, uint _scoringDeadline) private {
        projectIds.push(_projectId);
        scoringsMap[_projectId] = ScoringInfo(_scoringAddress, _acceptingDeadline, _scoringDeadline, _areas);

        for (uint i = 0; i < _areas.length; i++) {
            scoringsMap[_projectId].areaScorings[_areas[i]] = AreaScoring(_areaExpertCounts[i], new address[](0));
        }
    }

    function addOfferInternal(uint _projectId, uint _area, address _expert, uint _state) private {
        scoringsMap[_projectId].areaScorings[_area].offers.push(_expert);

        setOfferStateInternal(_projectId, _area, _expert, _state);
    }

    function setOfferStateInternal(uint _projectId, uint _area, address _expert, uint _state) private {
        if (scoringsMap[_projectId].areaScorings[_area].offerStates[_expert] != _state)
            scoringsMap[_projectId].areaScorings[_area].offerStates[_expert] = _state;
    }

    function setScoringDeadlineInternal(uint _projectId, uint _deadline) private {
        if (scoringsMap[_projectId].scoringDeadline != _deadline)
            scoringsMap[_projectId].scoringDeadline = _deadline;
    }

    function setRequiredExpertsCount(uint _projectId, uint _area, uint count) private {
        scoringsMap[_projectId].areaScorings[_area].requiredExpertsCount = count;
    }
}