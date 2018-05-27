pragma solidity ^ 0.4.24;

import "./Owned.sol";
import "./Scoring.sol";
import "./PrivateScoring.sol";
import "./ExpertsRegistry.sol";
import "./RandomGenerator.sol";
import "./ScoringsRegistry.sol";

contract ScoringOffersManager is Owned {

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
    address public privateScoringManagerAddress;

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
        require(msg.sender == scoringManagerAddress || msg.sender == privateScoringManagerAddress);
        _;
    }

    modifier onlyAdministrators {
        require(administratorsRegistry.isAdministrator(msg.sender));
        _;
    }

    function generate(uint _projectId, uint[] _areas) external onlyScoringManager {
        require(!hasOffers(_projectId, _areas), "offers for specified scoring were already generated");

        for (uint i = 0; i < _areas.length; i++) {
            generateInArea(_projectId, _areas[i]);
        }

        uint acceptingDeadline = now + offerExpirationPeriod;
        scoringsRegistry.setAcceptingDeadline(_projectId, acceptingDeadline);

        uint scoringDeadline = acceptingDeadline + scoringExpirationPeriod;
        scoringsRegistry.setScoringDeadline(_projectId, scoringDeadline);
    }

    function regenerate(uint _projectId) external onlyAdministrators {
        address scoringAddress = scoringsRegistry.getScoringAddressById(_projectId);
        require(scoringAddress != 0, "scoring for specified project is not started yet");

        Scoring scoring = Scoring(scoringAddress);
        uint[] memory areas = scoring.getAreas();
        require(!hasPendingOffers(_projectId, areas), "there are still pending offers for specified scoring");

        for (uint i = 0; i < areas.length; i++) {
            generateInArea(_projectId, areas[i]);

            updateExpiredOffersState(_projectId, areas[i]);
        }

        uint acceptingDeadline = now + offerExpirationPeriod;
        scoringsRegistry.setAcceptingDeadline(_projectId, acceptingDeadline);

        uint scoringDeadline = acceptingDeadline + scoringExpirationPeriod;
        scoringsRegistry.setScoringDeadline(_projectId, scoringDeadline);
    }

    function set(uint _projectId, uint[] _areas, address[] _experts) external onlyAdministrators {
        for (uint i = 0; i < _areas.length; i++) {
            uint area = _areas[i];
            address expert = _experts[i];

            require(isOfferReadyForScoring(expert, _projectId, area) || getVacantExpertPositionsCount(_projectId, area) > 0);
            require(expertsRegistry.isApproved(expert, area));

            if (doesOfferExist(_projectId, area, expert)) {
                setOfferState(_projectId, area, expert, OfferState.Accepted);
            } else {
                scoringsRegistry.addOffer(_projectId, area, expert, uint(OfferState.Accepted));
            }

            uint scoringDeadline = now + scoringExpirationPeriod;
            scoringsRegistry.setScoringDeadline(_projectId, scoringDeadline);
        }
    }

    function forceSet(uint _projectId, uint[] _expertAreas, address[] _experts) external {
        require(msg.sender == privateScoringManagerAddress || administratorsRegistry.isAdministrator(msg.sender));

        removeNotActualOffers(_projectId, _expertAreas, _experts);

        for (uint k = 0; k < _expertAreas.length; k++) {
            uint area = _expertAreas[k];
            address expert = _experts[k];

            require(expertsRegistry.isApproved(expert, area));

            if (doesOfferExist(_projectId, area, expert)) {
                if (getOfferState(_projectId, area, expert) != OfferState.Finished) {
                    setOfferState(_projectId, area, expert, OfferState.Accepted);
                }
            } else {
                scoringsRegistry.addOffer(_projectId, area, expert, uint(OfferState.Accepted));
                scoringsRegistry.incrementRequiredExpertsCount(_projectId, area);
            }
        }
    }

    function get(uint _projectId) external view returns(uint[] _areas, address[] _experts, uint[] _states, uint _scoringDeadline, uint _acceptingDeadline) {
        uint offersCount = getOffersCount(_projectId);
        _areas = new uint[](offersCount);
        _states = new uint[](offersCount);
        _experts = new address[](offersCount);
        _acceptingDeadline = scoringsRegistry.getAcceptingDeadline(_projectId);
        _scoringDeadline = scoringsRegistry.getScoringDeadline(_projectId);

        uint resutIndex = 0;
        address scoringAddress = scoringsRegistry.getScoringAddressById(_projectId);
        require(scoringAddress != 0, "scoring for specified project is not started yet");

        uint[] memory areas = Scoring(scoringAddress).getAreas();
        for (uint i = 0; i < areas.length; i++) {
            address[] memory areaOffers = scoringsRegistry.getOffers(_projectId, areas[i]);
            for (uint j = 0; j < areaOffers.length; j++) {
                address expert = areaOffers[j];

                _areas[resutIndex] = areas[i];
                _experts[resutIndex] = expert;
                _states[resutIndex] = scoringsRegistry.getOfferState(_projectId, areas[i], expert);

                resutIndex++;
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
    }

    function finish(uint _projectId, uint _area, address _expert) external onlyScoringManager {
        require(doesOfferExist(_projectId, _area, _expert), "offer does not exist");
        require(isOfferReadyForScoring(_expert, _projectId, _area), "offer is not in valid state for scoring");

        setOfferState(_projectId, _area, _expert, OfferState.Finished);
    }

    function setExpertsRegistry(address _address) public onlyOwner {
        require(_address != 0);
        expertsRegistry = ExpertsRegistry(_address);
    }

    function setScoringManager(address _address) public onlyOwner {
        require(_address != 0);
        scoringManagerAddress = _address;
    }

    function setPrivateScoringManager(address _address) public onlyOwner {
        require(_address != 0);
        privateScoringManagerAddress = _address;
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

    function getOffersCount(uint _projectId) private view returns(uint) {
        uint result = 0;
        address scoringAddress = scoringsRegistry.getScoringAddressById(_projectId);
        require(scoringAddress != 0, "scoring for specified project is not started yet");

        uint[] memory areas = Scoring(scoringAddress).getAreas();
        for (uint i = 0; i < areas.length; i++) {
            result += scoringsRegistry.getOffers(_projectId, areas[i]).length;
        }
        return result;
    }

    function hasPendingOffers(uint _projectId, uint[] _areas) private view returns(bool) {
        for (uint i = 0; i < _areas.length; i++) {
            address[] memory offers = scoringsRegistry.getOffers(_projectId, _areas[i]);
            for (uint j = 0; j < offers.length; j++) {
                if (isOfferPending(_projectId, _areas[i], offers[j]))
                    return true;
            }
        }
        return false;
    }

    function hasOffers(uint _projectId, uint[] _areas) private view returns(bool) {
        for (uint i = 0; i < _areas.length; i++) {
            if (scoringsRegistry.getOffers(_projectId, _areas[i]).length > 0) {
                return true;
            }
        }
        return false;
    }

    function generateInArea(uint _projectId, uint _area) private {
        uint expertsCount = getVacantExpertPositionsCount(_projectId, _area);
        require(expertsCount > 0);

        uint[] memory indices = generateExpertIndices(_projectId, _area, expertsCount);
        for (uint i = 0; i < indices.length; i++) {
            address expert = expertsRegistry.expertsByAreaMap(_area, indices[i]);
            scoringsRegistry.addOffer(_projectId, _area, expert, uint(OfferState.Pending));
        }
    }

    function isOfferReadyForScoring(address _expert, uint _projectId, uint _area) private view returns(bool) {
        return getOfferState(_projectId, _area, _expert) == OfferState.Accepted &&
            scoringsRegistry.getScoringDeadline(_projectId) >= now;
    }

    function isOfferPending(uint _projectId, uint _area, address _expert) private view returns(bool) {
        return getOfferState(_projectId, _area, _expert) == OfferState.Pending &&
            scoringsRegistry.getAcceptingDeadline(_projectId) >= now;
    }

    function isOfferFinished(uint _projectId, uint _area, address _expert) private view returns(bool) {
        return getOfferState(_projectId, _area, _expert) == OfferState.Finished;
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
        uint acceptingDeadline = scoringsRegistry.getAcceptingDeadline(_projectId);
        uint scoringDeadline = scoringsRegistry.getScoringDeadline(_projectId);
        for (uint i = 0; i < areaOffers.length; i++) {
            address expert = areaOffers[i];
            OfferState state = getOfferState(_projectId, _area, expert);
            if ((state == OfferState.Pending && acceptingDeadline < now) || (state == OfferState.Accepted && scoringDeadline < now)) {
                setOfferState(_projectId, _area, expert, OfferState.Expired);
            }
        }
    }

    function removeNotActualOffers(uint _projectId, uint[] _expertAreas, address[] _experts) private {
        address scoringAddress = scoringsRegistry.getScoringAddressById(_projectId);
        require(scoringAddress != 0, "scoring for specified project is not started yet");

        PrivateScoring scoring = PrivateScoring(scoringAddress);
        uint[] memory scoringAreas = scoring.getAreas();
        for (uint i = 0; i < scoringAreas.length; i++) {
            address[] memory areaOffers = scoringsRegistry.getOffers(_projectId, scoringAreas[i]);
            for (uint j = 0; j < areaOffers.length; j++) {
                if (!containsOffer(_expertAreas, _experts, scoringAreas[i], areaOffers[j])) {
                    if (getOfferState(_projectId, scoringAreas[i], areaOffers[j]) == OfferState.Finished) {
                        scoring.removeEstimates(areaOffers[j], scoringAreas[i]);
                    }
                    scoringsRegistry.removeOffer(_projectId, scoringAreas[i], areaOffers[j]);
                    scoringsRegistry.decrementRequiredExpertsCount(_projectId, scoringAreas[i]);
                }
            }
        }
    }

    function containsOffer(uint[] _areas, address[] _experts, uint _areaValue, address _expertValue) private pure returns(bool) {
        require(_areas.length == _experts.length);

        for (uint i = 0; i < _areas.length; i++) {
            if (_areas[i] == _areaValue && _experts[i] == _expertValue) {
                return true;
            }
        }
        return false;
    }

    function setOfferState(uint _projectId, uint _area, address _expert, OfferState _state) private {
        scoringsRegistry.setOfferState(_projectId, _area, _expert, uint(_state));
    }

    function getOfferState(uint _projectId, uint _area, address _expert) private view returns(OfferState) {
        return OfferState(scoringsRegistry.getOfferState(_projectId, _area, _expert));
    }
}