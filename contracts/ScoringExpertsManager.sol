pragma solidity ^ 0.4.19;

import "./Owned.sol";
import "./ExpertsRegistry.sol";
import "./RandomGenerator.sol";

contract ScoringExpertsManager is Owned {

    struct ScoringOffer {
        bool hasBeenMade;
        bool accepted;
        bool rejected;
    }

    ExpertsRegistry private expertsRegistry;
    address public scoringManagerAddress;

    uint public expertsCountMultiplier;
    uint public offerExpirationPeriod;

    mapping(uint => mapping(uint => address[])) offers;
    mapping(uint => mapping(uint => mapping(address => ScoringOffer))) offersMap;
    mapping(uint => uint) offerTimestamps;

    mapping(uint => mapping(uint => address[])) projectExperts;

    mapping(uint => mapping(uint => uint)) requestedProjectExpertCounts;

    function ScoringExpertsManager(uint _expertsCountMultiplier, uint _offerExpirationPeriodDays, address _expertsRegistryAddress) public {
        setExpertsRegistry(_expertsRegistryAddress);
        setExpertsCountMultiplier(_expertsCountMultiplier);
        setOfferExpirationPeriod(_offerExpirationPeriodDays);
    }

    modifier onlyScoringManager {
        require(msg.sender == scoringManagerAddress);
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

    function setExpertsCountMultiplier(uint _value) public onlyOwner {
        require(_value > 1);
        expertsCountMultiplier = _value;
    }

    function setOfferExpirationPeriod(uint _value) public onlyOwner {
        require(_value != 0);
        offerExpirationPeriod = _value * 1 days;
    }

    function selectExpertsForProject(uint _projectId, uint[] _areas, uint[] _areaExpertCounts) external {
        var offerTimestamp = offerTimestamps[_projectId];
        require(offerTimestamp == 0 || (now - offerTimestamp) > offerExpirationPeriod);

        for (uint i = 0; i < _areas.length; i++) {
            var areaExpertsCount = _areaExpertCounts[i];
            var area = _areas[i];

            requestedProjectExpertCounts[_projectId][area] = areaExpertsCount;

            var areaExperts = getExpertsInArea(area, areaExpertsCount);
            makeOffers(_projectId, area, areaExperts);
        }
    }

    function makeOffers(uint _projectId, uint _area, address[] _experts) private {
        offerTimestamps[_projectId] = now;

        for (uint i = 0; i < _experts.length; i++) {
            require(!offersMap[_projectId][_area][_experts[i]].hasBeenMade);

            offersMap[_projectId][_area][_experts[i]] = ScoringOffer({ hasBeenMade: true, accepted: false, rejected: false });
            offers[_projectId][_area].push(_experts[i]);
        }
    }

    function reject(uint _projectId, uint _area) external {
        var offer = offersMap[_projectId][_area][msg.sender];
        require(offer.hasBeenMade && !offer.accepted && !offer.rejected && (now - offerTimestamps[_projectId]) < offerExpirationPeriod);

        offer.rejected = true;
    }

    function accept(uint _projectId, uint _area) external {
        var offer = offersMap[_projectId][_area][msg.sender];
        require(offer.hasBeenMade && !offer.accepted && !offer.rejected && (now - offerTimestamps[_projectId]) < offerExpirationPeriod);
        require(requestedProjectExpertCounts[_projectId][_area] > projectExperts[_projectId][_area].length);

        offer.accepted = true;
        projectExperts[_projectId][_area].push(msg.sender);
    }

    function isExpertAssignedToProject(address _expert, uint _projectId, uint _area) external view returns(bool) {
        return offersMap[_projectId][_area][_expert].accepted;
    }

    function getExpertsInArea(uint _area, uint _requestedCount) private view returns(address[]) {
        var availableCount = expertsRegistry.getExpertsCountInArea(_area);
        require(availableCount >= _requestedCount);

        var extendedCount = _requestedCount * expertsCountMultiplier;
        if (availableCount <= extendedCount) {
            return getAllExpertsInArea(_area, availableCount);
        } else {
            var indices = RandomGenerator.generate(extendedCount, availableCount);
            return getExpertsByIndices(_area, indices);
        }
    }

    function getExpertsByIndices(uint _area, uint[] _indices) private view returns(address[]) {
        address[] memory result = new address[](_indices.length);
        for (uint i = 0; i < _indices.length; i++) {
            result[i] = expertsRegistry.areaExpertsMap(_area, _indices[i]);
        }
        return result;
    }

    function getAllExpertsInArea(uint _area, uint _count) private view returns(address[]) {
        address[] memory result = new address[](_count);
        for (uint i = 0; i < _count; i++) {
            result[i] = expertsRegistry.areaExpertsMap(_area, i);
        }
        return result;
    }
}