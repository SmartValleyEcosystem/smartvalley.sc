pragma solidity ^ 0.4.22;

import "./Owned.sol";
import "./ExpertsRegistry.sol";
import "./RandomGenerator.sol";
import "./ScoringsRegistry.sol";

contract ScoringExpertsManager is Owned {

    ExpertsRegistry public expertsRegistry;
    AdministratorsRegistry public administratorsRegistry;
    ScoringsRegistry public scoringsRegistry;
    address public scoringManagerAddress;

    uint public expertsCountMultiplier;
    uint public offerExpirationPeriod;
    uint public scoringExpirationPeriod;

    constructor(uint _expertsCountMultiplier,
                uint _offerExpirationPeriodDays,
                uint _scoringExpirationPeriodDays,
                address _expertsRegistryAddress,
                address _administratorsRegistryAddress,
                address _scoringsRegistryAddress) public {
        setExpertsRegistry(_expertsRegistryAddress);
        setExpertsCountMultiplier(_expertsCountMultiplier);
        setOfferExpirationPeriod(_offerExpirationPeriodDays);
        setScoringExpirationPeriod(_scoringExpirationPeriodDays);
        setAdministratorsRegistry(_administratorsRegistryAddress);
        setScoringsRegistry(_scoringsRegistryAddress);
    }

    modifier onlyScoringManager {
        require(msg.sender == scoringManagerAddress);
        _;
    }

    modifier onlyAdministrators {
        require(administratorsRegistry.isAdministrator(msg.sender));
        _;
    }

    function setExpertsRegistry(address _address) public onlyOwner {
        require(_address != 0);
        expertsRegistry = ExpertsRegistry(_address);
    }

    function setScoringManager(address _address) public onlyOwner {
        require(_address != 0);
        scoringManagerAddress = _address;
    }

    function setAdministratorsRegistry(address _address) public onlyOwner {
        require(_address != 0);
        administratorsRegistry = AdministratorsRegistry(_address);
    }

    function setScoringsRegistry(address _address) public onlyOwner {
        require(_address != 0);
        scoringsRegistry = ScoringsRegistry(_address);
    }

    function setExpertsCountMultiplier(uint _value) public onlyOwner {
        require(_value >= 1);
        expertsCountMultiplier = _value;
    }

    function setOfferExpirationPeriod(uint _days) public onlyOwner {
        require(_days != 0);
        offerExpirationPeriod = _days * 1 days;
    }

    function setScoringExpirationPeriod(uint _days) public onlyOwner {
        require(_days != 0);
        scoringExpirationPeriod = _days * 1 days;
    }

    function selectExperts(uint _projectId) external onlyScoringManager {
        require(scoringsRegistry.getScoringAddressById(_projectId) != 0, "scoring for specified project is not started yet");
        require(!hasOffers(_projectId), "offers for specified scoring were already selected");

        uint[] memory areas = scoringsRegistry.getScoringAreas(_projectId);
        for (uint i = 0; i < areas.length; i++) {
            makeOffers(_projectId, areas[i]);
        }
    }

    function selectMissingExperts(uint _projectId) external onlyAdministrators {
        require(scoringsRegistry.getScoringAddressById(_projectId) != 0, "scoring for specified project is not started yet");
        require(!hasPendingOffers(_projectId), "there are still pending offers for specified scoring");

        uint[] memory areas = scoringsRegistry.getScoringAreas(_projectId);
        for (uint i = 0; i < areas.length; i++) {
            scoringsRegistry.setPendingOffersExpirationTimestamp(_projectId, now + offerExpirationPeriod);
            makeOffers(_projectId, areas[i]);
        }
    }

    function setExperts(uint _projectId, uint[] _areas, address[] _experts) external onlyAdministrators {
        for (uint i = 0; i < _areas.length; i++) {
            uint area = _areas[i];
            address expert = _experts[i];

            uint vacantExpertPositionCount = scoringsRegistry.getVacantExpertPositionCount(_projectId, area);
            require(vacantExpertPositionCount > 0);

            uint offerState = scoringsRegistry.getOfferState(_projectId, area, expert);
            require(offerState != 1);

            if (offerState == 0) {
                scoringsRegistry.addOffer(_projectId, area, expert, 1, now + scoringExpirationPeriod);
            } else {
                scoringsRegistry.setOfferState(_projectId, area, expert, 1);
                scoringsRegistry.setScoringDeadline(_projectId, area, expert, now + scoringExpirationPeriod);
            }

            scoringsRegistry.setVacantExpertPositionCount(_projectId, area, vacantExpertPositionCount - 1);
        }
    }

    function getOffers(uint _projectId) external view returns(uint[] _areas, address[] _experts, uint[] _states, uint[] _deadlines) {
        uint offersCount = getOffersCount(_projectId);

        _areas = new uint[](offersCount);
        _states = new uint[](offersCount);
        _experts = new address[](offersCount);
        _deadlines = new uint[](offersCount);

        uint currentOfferIndex = 0;
        uint[] memory areas = scoringsRegistry.getScoringAreas(_projectId);
        for (uint i = 0; i < areas.length; i++) {
            uint area = areas[i];
            address[] memory areaOffers = scoringsRegistry.getOffers(_projectId, area);
            for (uint j = 0; j < areaOffers.length; j++) {
                address expert = areaOffers[j];

                _areas[currentOfferIndex] = area;
                _experts[currentOfferIndex] = expert;
                _states[currentOfferIndex] = scoringsRegistry.getOfferState(_projectId, area, expert);
                _deadlines[currentOfferIndex] = scoringsRegistry.getScoringDeadline(_projectId, area, expert);

                currentOfferIndex++;
            }
        }
    }

    function reject(uint _projectId, uint _area) external {
        require(doesOfferExist(_projectId, _area, msg.sender), "offer does not exist");
        require(isOfferPending(_projectId, _area, msg.sender), "offer is not in pending state");

        scoringsRegistry.setOfferState(_projectId, _area, msg.sender, 2);
    }

    function accept(uint _projectId, uint _area) external {
        require(doesOfferExist(_projectId, _area, msg.sender), "offer does not exist");
        require(isOfferPending(_projectId, _area, msg.sender), "offer is not in pending state");

        uint vacantExpertPositionCount = scoringsRegistry.getVacantExpertPositionCount(_projectId, _area);
        require(vacantExpertPositionCount > 0);

        scoringsRegistry.setOfferState(_projectId, _area, msg.sender, 1);
        scoringsRegistry.setScoringDeadline(_projectId, _area, msg.sender, now + scoringExpirationPeriod);
        scoringsRegistry.setVacantExpertPositionCount(_projectId, _area, vacantExpertPositionCount - 1);
    }

    function finish(uint _projectId, uint _area, address _expert) external onlyScoringManager {
        require(doesOfferExist(_projectId, _area, _expert), "offer does not exist");
        require(isOfferReadyForScoring(_expert, _projectId, _area), "offer is not in valid state for scoring");

        scoringsRegistry.setOfferState(_projectId, _area, _expert, 3);
    }

    function getOffersCount(uint _projectId) private view returns(uint) {
        uint result = 0;
        uint[] memory areas = scoringsRegistry.getScoringAreas(_projectId);
        for (uint i = 0; i < areas.length; i++) {
            result += scoringsRegistry.getOffers(_projectId, areas[i]).length;
        }
        return result;
    }

    function hasPendingOffers(uint _projectId) private view returns(bool) {
        uint[] memory areas = scoringsRegistry.getScoringAreas(_projectId);
        for (uint i = 0; i < areas.length; i++) {
            address[] memory offers = scoringsRegistry.getOffers(_projectId, areas[i]);
            for (uint j = 0; j < offers.length; j++) {
                if (isOfferPending(_projectId, areas[i], offers[j]))
                    return true;
            }
        }
        return false;
    }

    function hasOffers(uint _projectId) private view returns(bool) {
        uint[] memory areas = scoringsRegistry.getScoringAreas(_projectId);
        for (uint i = 0; i < areas.length; i++) {
            if (scoringsRegistry.getOffers(_projectId, areas[i]).length > 0) {
                return true;
            }
        }
        return false;
    }

    function makeOffers(uint _projectId, uint _area) private {
        uint expertsCount = scoringsRegistry.getVacantExpertPositionCount(_projectId, _area);
        require(expertsCount > 0);

        uint[] memory indices = generateExpertIndices(_projectId, _area, expertsCount);
        for (uint i = 0; i < indices.length; i++) {
            address expert = expertsRegistry.expertsByAreaMap(_area, indices[i]);
            scoringsRegistry.addOffer(_projectId, _area, expert, 0, 0);
        }
    }

    function isOfferReadyForScoring(address _expert, uint _projectId, uint _area) private view returns(bool) {
        return scoringsRegistry.getOfferState(_projectId, _area, _expert) == 1
            && scoringsRegistry.getScoringDeadline(_projectId, _area, _expert) >= now;
    }

    function isOfferPending(uint _projectId, uint _area, address _expert) private view returns(bool) {
        return scoringsRegistry.getOfferState(_projectId, _area, _expert) == 0 
            && scoringsRegistry.getPendingOffersExpirationTimestamp(_projectId) >= now;
    }

    function doesOfferExist(uint _projectId, uint _area, address _expert) private view returns(bool) {
        address[] memory offers = scoringsRegistry.getOffers(_projectId, _area);
        for (uint i = 0; i < offers.length; i++) {
            if (offers[i] == _expert) {
                return true;
            }
        }
        return false;
    }

    function generateExpertIndices(uint _projectId, uint _area, uint _requestedExpertsCount) private view returns(uint[]) {
        address[] memory offers = scoringsRegistry.getOffers(_projectId, _area);
        uint[] memory indicesToExclude = expertsRegistry.getExpertsIndices(_area, offers);
        uint existingExpertsCount = expertsRegistry.getExpertsCountInArea(_area);
        uint availableExpertsCount = existingExpertsCount - indicesToExclude.length;

        require(availableExpertsCount >= _requestedExpertsCount);

        uint extendedExpertsCount = _requestedExpertsCount * expertsCountMultiplier;
        uint countToGenerate = availableExpertsCount < extendedExpertsCount ? availableExpertsCount : extendedExpertsCount;
        return RandomGenerator.generate(countToGenerate, existingExpertsCount, indicesToExclude, _area);
    }
}