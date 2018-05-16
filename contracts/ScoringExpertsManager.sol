pragma solidity ^ 0.4.23;

import "./Owned.sol";
import "./ExpertsRegistry.sol";
import "./RandomGenerator.sol";
import "./ScoringsRegistry.sol";

contract ScoringExpertsManager is Owned {

    enum OfferState {
        Pending,
        Accepted,
        Rejected,
        Finished,
        Expired
    }

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

        scoringsRegistry.setPendingOffersExpirationTimestamp(_projectId, now + offerExpirationPeriod);
    }

    function selectMissingExperts(uint _projectId) external onlyAdministrators {
        require(scoringsRegistry.getScoringAddressById(_projectId) != 0, "scoring for specified project is not started yet");
        require(!hasPendingOffers(_projectId), "there are still pending offers for specified scoring");

        uint[] memory areas = scoringsRegistry.getScoringAreas(_projectId);
        for (uint i = 0; i < areas.length; i++) {
            makeOffers(_projectId, areas[i]);

            updateExpiredOffersState(_projectId, areas[i]);
        }

        scoringsRegistry.setPendingOffersExpirationTimestamp(_projectId, now + offerExpirationPeriod);
    }

    function setExperts(uint _projectId, uint[] _areas, address[] _experts) external onlyAdministrators {
        for (uint i = 0; i < _areas.length; i++) {
            uint area = _areas[i];
            address expert = _experts[i];

            require(isOfferReadyForScoring(expert, _projectId, area) || getVacantExpertPositionsCount(_projectId, area) > 0);

            uint scoringDeadline = now + scoringExpirationPeriod;

            if (doesOfferExist(_projectId, area, expert)) {
                setOfferState(_projectId, area, expert, OfferState.Accepted);
                scoringsRegistry.setScoringDeadline(_projectId, area, expert, scoringDeadline);
            } else {
                scoringsRegistry.addOffer(_projectId, area, expert, uint(OfferState.Accepted), scoringDeadline);
            }
        }
    }

    function getOffers(uint _projectId) external view returns(uint[] _areas, address[] _experts, uint[] _states, uint[] _deadlines, uint _expirationTimestamp) {
        uint offersCount = getOffersCount(_projectId);

        _areas = new uint[](offersCount);
        _states = new uint[](offersCount);
        _experts = new address[](offersCount);
        _deadlines = new uint[](offersCount);
        _expirationTimestamp = scoringsRegistry.getPendingOffersExpirationTimestamp(_projectId);

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

        setOfferState(_projectId, _area, msg.sender, OfferState.Rejected);
    }

    function accept(uint _projectId, uint _area) external {
        require(doesOfferExist(_projectId, _area, msg.sender), "offer does not exist");
        require(isOfferPending(_projectId, _area, msg.sender), "offer is not in pending state");
        require(getVacantExpertPositionsCount(_projectId, _area) > 0);

        setOfferState(_projectId, _area, msg.sender, OfferState.Accepted);
        scoringsRegistry.setScoringDeadline(_projectId, _area, msg.sender, now + scoringExpirationPeriod);
    }

    function finish(uint _projectId, uint _area, address _expert) external onlyScoringManager {
        require(doesOfferExist(_projectId, _area, _expert), "offer does not exist");
        require(isOfferReadyForScoring(_expert, _projectId, _area), "offer is not in valid state for scoring");

        setOfferState(_projectId, _area, _expert, OfferState.Finished);
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
        uint expertsCount = getVacantExpertPositionsCount(_projectId, _area);
        require(expertsCount > 0);

        uint[] memory indices = generateExpertIndices(_projectId, _area, expertsCount);
        for (uint i = 0; i < indices.length; i++) {
            address expert = expertsRegistry.expertsByAreaMap(_area, indices[i]);
            scoringsRegistry.addOffer(_projectId, _area, expert, uint(OfferState.Pending), 0);
        }
    }

    function isOfferReadyForScoring(address _expert, uint _projectId, uint _area) private view returns(bool) {
        return getOfferState(_projectId, _area, _expert) == OfferState.Accepted &&
            scoringsRegistry.getScoringDeadline(_projectId, _area, _expert) >= now;
    }

    function isOfferPending(uint _projectId, uint _area, address _expert) private view returns(bool) {
        return getOfferState(_projectId, _area, _expert) == OfferState.Pending &&
            scoringsRegistry.getPendingOffersExpirationTimestamp(_projectId) >= now;
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

    function getVacantExpertPositionsCount(uint _projectId, uint _area) private view returns(uint) {
        uint currentExpertsCount = 0;
        address[] memory areaOffers = scoringsRegistry.getOffers(_projectId, _area);
        for (uint i = 0; i < areaOffers.length; i++) {
            if (isOfferReadyForScoring(areaOffers[i], _projectId, _area)) {
                currentExpertsCount++;
            }
        }
        return scoringsRegistry.getRequiredExpertsCount(_projectId, _area) - currentExpertsCount;
    }

    function updateExpiredOffersState(uint _projectId, uint _area) private {
        address[] memory areaOffers = scoringsRegistry.getOffers(_projectId, _area);
        for (uint i = 0; i < areaOffers.length; i++) {
            address expert = areaOffers[i];
            uint expirationTimestamp = scoringsRegistry.getPendingOffersExpirationTimestamp(_projectId);
            if (getOfferState(_projectId, _area, expert) == OfferState.Pending && expirationTimestamp < now) {
                setOfferState(_projectId, _area, expert, OfferState.Expired);
            }
        }
    }

    function setOfferState(uint _projectId, uint _area, address _expert, OfferState _state) private {
        scoringsRegistry.setOfferState(_projectId, _area, _expert, uint(_state));
    }

    function getOfferState(uint _projectId, uint _area, address _expert) private view returns(OfferState) {
        return OfferState(scoringsRegistry.getOfferState(_projectId, _area, _expert));
    }
}