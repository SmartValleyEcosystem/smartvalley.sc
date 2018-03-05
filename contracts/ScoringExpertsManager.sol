pragma solidity ^ 0.4.19;

import "./Owned.sol";
import "./ExpertsRegistry.sol";
import "./RandomGenerator.sol";

contract ScoringExpertsManager is Owned {

    ExpertsRegistry private expertsRegistry;
    AdministratorsRegistry private administratorsRegistry;

    address public scoringManagerAddress;

    uint public expertsCountMultiplier;
    uint public offerExpirationPeriod;

    // State contains one of following values:
    // - 0: No offer created
    // - 1: Offer is accepted
    // - 2: Offer is rejected
    // - timespan: Offer is pending (from the specified timespan)
    mapping(uint => mapping(uint => mapping(address => uint))) offerStates;
    mapping(uint => mapping(uint => address[])) offers;
    mapping(uint => mapping(uint => uint)) vacantExpertPositionCounts;
    mapping(uint => uint[]) projectAreas;

    function ScoringExpertsManager(uint _expertsCountMultiplier, uint _offerExpirationPeriodDays, address _expertsRegistryAddress, address _administratorsRegistryAddress) public {
        setExpertsRegistry(_expertsRegistryAddress);
        setExpertsCountMultiplier(_expertsCountMultiplier);
        setOfferExpirationPeriod(_offerExpirationPeriodDays);
        setAdministratorsRegistry(_administratorsRegistryAddress);
    }

    modifier onlyScoringManager {
        require(msg.sender == scoringManagerAddress);
        _;
    }

    modifier onlyAdministrators {
        require(administratorsRegistry.isAdministrator(msg.sender));
        _;
    }

    function setExpertsRegistry(address _expertsRegistryAddress) public onlyOwner {
        require(_expertsRegistryAddress != 0);
        expertsRegistry = ExpertsRegistry(_expertsRegistryAddress);
    }

    function setScoringManager(address _scoringManagerAddress) public onlyOwner {
        require(_scoringManagerAddress != 0);
        scoringManagerAddress = _scoringManagerAddress;
    }

    function setAdministratorsRegistry(address _administratorsRegistryAddress) public onlyOwner {
        require(_administratorsRegistryAddress != 0);
        administratorsRegistry = AdministratorsRegistry(_administratorsRegistryAddress);
    }

    function setExpertsCountMultiplier(uint _value) public onlyOwner {
        require(_value >= 1);
        expertsCountMultiplier = _value;
    }

    function setOfferExpirationPeriod(uint _value) public onlyOwner {
        require(_value != 0);
        offerExpirationPeriod = _value * 1 days;
    }

    function selectExperts(uint _projectId, uint[] _areas, uint[] _areaExpertCounts) external onlyScoringManager {
        require(_areas.length != 0 && _areas.length == _areaExpertCounts.length);
        require(projectAreas[_projectId].length == 0);

        projectAreas[_projectId] = _areas;

        for (uint i = 0; i < _areas.length; i++) {
            vacantExpertPositionCounts[_projectId][_areas[i]] = _areaExpertCounts[i];
            makeOffers(_projectId, _areas[i]);
        }
    }

    function selectMissingExperts(uint _projectId) external onlyAdministrators {
        require(!hasAnyPendingOffers(_projectId));

        uint[] storage areas = projectAreas[_projectId];
        for (uint i = 0; i < areas.length; i++) {
            makeOffers(_projectId, areas[i]);
        }
    }

    function setExperts(uint _projectId, uint[] _areas, address[] _experts) external onlyAdministrators {
        for (uint i = 0; i < _areas.length; i++) {
            uint area = _areas[i];
            require(vacantExpertPositionCounts[_projectId][area] > 0);

            uint offerState = offerStates[_projectId][area][expert];
            require(offerState != 1);

            address expert = _experts[i];
            if (offerState == 0) {
                offers[_projectId][area].push(expert);
            }

            offerStates[_projectId][area][expert] = 1;
            vacantExpertPositionCounts[_projectId][area]--;
        }
    }

    function getOffers(uint _projectId) external view returns(uint[] _areas, address[] _experts, uint[] _states) {
        uint offersCount = getOffersCount(_projectId);
        _areas = new uint[](offersCount);
        _states = new uint[](offersCount);
        _experts = new address[](offersCount);

        uint currentOfferIndex = 0;
        uint[] storage areas = projectAreas[_projectId];
        for (uint i = 0; i < areas.length; i++) {
            uint area = areas[i];
            address[] storage areaOffers = offers[_projectId][area];
            for (uint j = 0; j < areaOffers.length; j++) {
                address expert = areaOffers[j];

                _areas[currentOfferIndex] = area;
                _experts[currentOfferIndex] = expert;
                _states[currentOfferIndex] = offerStates[_projectId][area][expert];

                currentOfferIndex++;
            }
        }
    }

    function getOffersCount(uint _projectId) private view returns(uint) {
        uint result = 0;
        uint[] storage areas = projectAreas[_projectId];
        for (uint i = 0; i < areas.length; i++) {
            uint area = areas[i];
            result += offers[_projectId][area].length;
        }
        return result;
    }

    function hasAnyPendingOffers(uint _projectId) private view returns (bool) {
        uint[] storage areas = projectAreas[_projectId];
        for (uint i = 0; i < areas.length; i++) {
            uint area = areas[i];
            address[] storage areaOffers = offers[_projectId][area];
            for (uint j = 0; j < areaOffers.length; j++) {
                if (offerStates[_projectId][area][areaOffers[j]] > now)
                    return true;
            }
        }
        return false;
    }

    function makeOffers(uint _projectId, uint _area) private {
        uint expertsCount = vacantExpertPositionCounts[_projectId][_area];
        require(expertsCount > 0);

        uint[] memory indices = getExpertIndicesInArea(_projectId, _area, expertsCount);
        for (uint i = 0; i < indices.length; i++) {
            address expert = expertsRegistry.areaExpertsMap(_area, indices[i]);
            require(offerStates[_projectId][_area][expert] == 0);

            offerStates[_projectId][_area][expert] = now + offerExpirationPeriod;
            offers[_projectId][_area].push(expert);
        }
    }

    function reject(uint _projectId, uint _area) external {
        require(offerStates[_projectId][_area][msg.sender] > now);

        offerStates[_projectId][_area][msg.sender] = 2;
    }

    function accept(uint _projectId, uint _area) external {
        require(offerStates[_projectId][_area][msg.sender] > now);
        require(vacantExpertPositionCounts[_projectId][_area] > 0);

        offerStates[_projectId][_area][msg.sender] = 1;
        vacantExpertPositionCounts[_projectId][_area]--;
    }

    function isExpertAssignedToProject(address _expert, uint _projectId, uint _area) external view returns(bool) {
        return offerStates[_projectId][_area][_expert] == 1;
    }

    function getExpertIndicesInArea(uint _projectId, uint _area, uint _requestedCount) private view returns(uint[]) {
        uint[] memory indicesToExclude = getIndices(_area, offers[_projectId][_area]);
        uint existingCount = expertsRegistry.getExpertsCountInArea(_area);
        uint availableCount = existingCount - indicesToExclude.length;

        require(availableCount >= _requestedCount);

        uint extendedCount = _requestedCount * expertsCountMultiplier;
        uint countToGenerate = availableCount < extendedCount ? availableCount : extendedCount;
        return RandomGenerator.generate(countToGenerate, existingCount, indicesToExclude);
    }

    function getIndices(uint _area, address[] _experts) private view returns(uint[]) {
        uint[] memory result = new uint[](_experts.length);
        for (uint i = 0; i < _experts.length; i++) {
            result[i] = expertsRegistry.getExpertIndex(_experts[i], _area);
        }
        return result;
    }
}