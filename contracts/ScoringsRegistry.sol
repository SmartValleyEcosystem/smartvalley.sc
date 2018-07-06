pragma solidity ^ 0.4.24;

import "./Owned.sol";
import "./Scoring.sol";
import "./ArrayExtensions.sol";

contract ScoringsRegistry is Owned {

    using ArrayExtensions for address[];

    struct AreaScoring {
        uint requiredExpertsCount;
        address[] offers;
        mapping(address => uint) offerStates;
    }

    struct ScoringInfo {
        address contractAddress;
        uint acceptingDeadline;
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

    function getScoringsCount() external view returns (uint) {
        return projectIds.length;
    }

    function getScoringAddressByIndex(uint _index) external view returns (address) {
        return scoringsMap[projectIds[_index]].contractAddress;
    }

    function getProjectIdByIndex(uint _index) external view returns (uint) {
        return projectIds[_index];
    }

    function getScoringAddressById(uint _projectId) external view returns (address) {
        return scoringsMap[_projectId].contractAddress;
    }

    function addScoring(address _scoringAddress, uint _projectId, uint[] _areas, uint[] _areaExpertCounts) external onlyScoringManager {
        addScoringInternal(_scoringAddress, _projectId, _areas, _areaExpertCounts, 0);
    }

    function setScoringAddress(uint _projectId, address _contractAddress) external onlyScoringManager {
        scoringsMap[_projectId].contractAddress = _contractAddress;
    }

    function getOffers(uint _projectId, uint _area) external view returns (address[]) {
        return scoringsMap[_projectId].areaScorings[_area].offers;
    }

    function addOffer(uint _projectId, uint _area, address _expert, uint _state) external onlyScoringOffersManager {
        addOfferInternal(_projectId, _area, _expert, _state);
    }

    function removeOffer(uint _projectId, uint _area, address _expert) external onlyScoringOffersManager {
        setOfferStateInternal(_projectId, _area, _expert, 0);
        scoringsMap[_projectId].areaScorings[_area].offers.remove(_expert);
    }

    function getOfferState(uint _projectId, uint _area, address _expert) external view returns(uint) {
        return scoringsMap[_projectId].areaScorings[_area].offerStates[_expert];
    }

    function setOfferState(uint _projectId, uint _area, address _expert, uint _state) external onlyScoringOffersManager {
        setOfferStateInternal(_projectId,_area, _expert, _state);
    }

    function getAcceptingDeadline(uint _projectId) external view returns(uint) {
        return scoringsMap[_projectId].acceptingDeadline;
    }

    function setAcceptingDeadline(uint _projectId, uint _value) external onlyScoringOffersManager {
        scoringsMap[_projectId].acceptingDeadline = _value;
    }

    function getRequiredExpertsCount(uint _projectId, uint _area) external view returns (uint) {
        return scoringsMap[_projectId].areaScorings[_area].requiredExpertsCount;
    }

    function getRequiredExpertsCounts(uint _projectId) external view returns (uint[] _counts, uint[] _areas) {
        address scoringAddress = scoringsMap[_projectId].contractAddress;
        _areas = Scoring(scoringAddress).getAreas();
        _counts = new uint[](_areas.length);

        for (uint i = 0; i < _areas.length; i++) {
            _counts[i] = scoringsMap[_projectId].areaScorings[_areas[i]].requiredExpertsCount;
        }
    }

    function incrementRequiredExpertsCount(uint _projectId, uint _area) external onlyScoringOffersManager {
        scoringsMap[_projectId].areaScorings[_area].requiredExpertsCount++;
    }

    function decrementRequiredExpertsCount(uint _projectId, uint _area) external onlyScoringOffersManager {
        scoringsMap[_projectId].areaScorings[_area].requiredExpertsCount--;
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

    function addScoringInternal(address _scoringAddress, uint _projectId, uint[] _areas, uint[] _areaExpertCounts, uint _acceptingDeadline) private {
        projectIds.push(_projectId);
        scoringsMap[_projectId] = ScoringInfo(_scoringAddress, _acceptingDeadline);

        for (uint i = 0; i < _areas.length; i++) {
            AreaScoring memory areaScoring;
            areaScoring.requiredExpertsCount = _areaExpertCounts[i];

            scoringsMap[_projectId].areaScorings[_areas[i]] = areaScoring;
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

    function setRequiredExpertsCount(uint _projectId, uint _area, uint count) private {
        scoringsMap[_projectId].areaScorings[_area].requiredExpertsCount = count;
    }
}