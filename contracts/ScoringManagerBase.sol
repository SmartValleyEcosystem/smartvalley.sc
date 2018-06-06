pragma solidity ^ 0.4.24;

import "./Owned.sol";
import "./Scoring.sol";
import "./ScoringOffersManager.sol";
import "./AdministratorsRegistry.sol";
import "./ScoringsRegistry.sol";
import "./ScoringParametersProvider.sol";

contract ScoringManagerBase is Owned {

    ScoringOffersManager public scoringOffersManager;
    ScoringsRegistry public scoringsRegistry;
    AdministratorsRegistry public administratorsRegistry;
    ScoringParametersProvider public scoringParametersProvider;

    constructor(address _scoringOffersManagerAddress,
                address _administratorsRegistryAddress,
                address _scoringsRegistryAddress,
                address _scoringParametersProviderAddress) public {

        setAdministratorsRegistry(_administratorsRegistryAddress);
        setScoringsRegistry(_scoringsRegistryAddress);
        setScoringOffersManager(_scoringOffersManagerAddress);
        setScoringParametersProvider(_scoringParametersProviderAddress);
    }

    modifier onlyAdministrators {
        require(administratorsRegistry.isAdministrator(msg.sender) || msg.sender == owner);
        _;
    }

    function submitEstimates(uint _projectId, uint _area, bytes32 _conclusionHash, uint[] _criterionIds, uint[] _scores, bytes32[] _commentHashes) external {
        require(_criterionIds.length == _scores.length && _scores.length == _commentHashes.length);

        scoringOffersManager.finish(_projectId, _area, msg.sender);

        Scoring scoring = Scoring(scoringsRegistry.getScoringAddressById(_projectId));
        scoring.submitEstimates(msg.sender, _area, _conclusionHash, _criterionIds, _scores, _commentHashes);
    }

    function updateScoringsOwner(uint _startIndex, uint _count, address _newScoringManager) external onlyOwner {
        uint scoringsCount = scoringsRegistry.getScoringsCount();
        require(_startIndex + _count <= scoringsCount && _newScoringManager != 0);

        for (uint i = _startIndex; i < _startIndex + _count; i++) {
            Scoring scoring = Scoring(scoringsRegistry.getScoringAddressByIndex(i));
            scoring.changeOwner(_newScoringManager);
        }
    }

    function confirmScoringsOwner(uint _startIndex, uint _count) external {
        uint scoringsAmount = scoringsRegistry.getScoringsCount();
        require(_startIndex + _count <= scoringsAmount);

        for (uint i = _startIndex; i < _startIndex + _count; i++) {
            Scoring scoring = Scoring(scoringsRegistry.getScoringAddressByIndex(i));
            scoring.confirmOwner();
        }
    }

    function setScoringOffersManager(address _address) public onlyOwner {
        require(_address != 0);
        scoringOffersManager = ScoringOffersManager(_address);
    }

    function setAdministratorsRegistry(address _address) public onlyOwner {
        require(_address != 0);
        administratorsRegistry = AdministratorsRegistry(_address);
    }

    function setScoringParametersProvider(address _address) public onlyOwner {
        require(_address != 0);
        scoringParametersProvider = ScoringParametersProvider(_address);
    }

    function setScoringsRegistry(address _address) public onlyOwner {
        require(_address != 0);
        scoringsRegistry = ScoringsRegistry(_address);
    }
}
