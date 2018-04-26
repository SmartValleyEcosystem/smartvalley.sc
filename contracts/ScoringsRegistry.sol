pragma solidity ^ 0.4.22;

import "./Owned.sol";

contract ScoringsRegistry is Owned {

    struct Scoring {
        uint id;
        address addr; 
        uint[] areas;    

        // State contains one of following values:
        // - 0: No offer created
        // - 1: Offer is accepted
        // - 2: Offer is rejected
        // - timespan: Offer is pending (from the specified timespan)       
        mapping(uint => mapping(address => uint)) offerStates;
        mapping(uint => address[]) offers;
        mapping(uint => uint) vacantExpertPositionCounts;        
    }
    
    Scoring[] public scorings;
    mapping(uint => Scoring) public scoringsMap;   

    address public scoringExpertsManagerAddress;
    address public scoringManagerAddress;
    address public migrationHost;

    modifier onlyScroingExpertsManager {
        require(scoringExpertsManagerAddress == msg.sender);
        _;
    }

    modifier onlyScoringManager {
        require(scoringManagerAddress == msg.sender);
        _;
    }

    modifier onlyMigrationHost {
        require(migrationHost == msg.sender);
        _;
    }   

    function setScoringExpertManager(address _scoringExpertsManagerAddress) external onlyOwner {
        require(_scoringExpertsManagerAddress != 0);
        scoringExpertsManagerAddress = _scoringExpertsManagerAddress;
    }

    function setScoringManager(address _scoringManagerAddress) external onlyOwner {
        require(_scoringManagerAddress != 0);
        scoringManagerAddress = _scoringManagerAddress;
    }

    function setMigrationHost(address _address) external onlyOwner {
        require(_address != 0);
        migrationHost = _address;
    }

    function getScoringsAmount() public view returns (uint) {        
        return scorings.length;
    }

    function getScoringAddressByIndex(uint index) public view returns (address) {       
        return scoringsMap[scorings[index].id].addr;
    }

    function getScoringIdByIndex(uint index) public view returns (uint) {
        return scorings[index].id;        
    }

    function getScoringAddressById(uint scoringId) public view returns (address) {      
        return scoringsMap[scoringId].addr;
    }     

    function getScoringAreas(uint _scoringId) public view returns (uint[]) {
        return scoringsMap[_scoringId].areas;
    }

    function addScoring(address _scoring, uint _scoringId, uint[] _areas) public onlyScoringManager {        
        addScoringInternal(_scoring, _scoringId, _areas);
    }

    function addScoringInternal(address _scoring, uint _scoringId, uint[] _areas) private {
        Scoring memory scoring = Scoring(_scoringId, _scoring, _areas);    
        scorings.push(scoring);
        scoringsMap[_scoringId] = scoring;        
    }

    function getOffers(uint _scoringId, uint _area) public view returns (address[]) {
        return scoringsMap[_scoringId].offers[_area];
    }

    function addOffer(uint _scoringId, uint _area, address _expert) public onlyScroingExpertsManager {   
        addOfferInternal(_scoringId, _area, _expert);
    }

    function addOfferInternal(uint _scoringId, uint _area, address _expert) private {   
        scoringsMap[_scoringId].offers[_area].push(_expert);
    }

    function getOfferState(uint _scoringId, uint _area, address _expert) public view returns (uint) {
        return scoringsMap[_scoringId].offerStates[_area][_expert];
    }

    function setOfferState(uint _scoringId, uint _area, address _expert, uint state) public onlyScroingExpertsManager {   
        setOfferStateInternal(_scoringId,_area, _expert, state);       
    } 

    function setOfferStateInternal(uint _scoringId, uint _area, address _expert, uint state) private {   
        scoringsMap[_scoringId].offerStates[_area][_expert] = state;
    } 

    function getVacantExpertPositionCounts(uint _scoringId, uint _area) public view returns (uint) {
        return scoringsMap[_scoringId].vacantExpertPositionCounts[_area];
    }

    function setVacantExpertPositionCount(uint _scoringId, uint _area, uint count) public onlyScroingExpertsManager {      
        setVacantExpertPositionCountInternal(_scoringId, _area, count);
    }

    function setVacantExpertPositionCountInternal(uint _scoringId, uint _area, uint count) private {      
        scoringsMap[_scoringId].vacantExpertPositionCounts[_area] = count;
    }

    function migrateScoringFromMigrationHost (uint _startIndex, uint _count) external onlyOwner {
        require(migrationHost != 0);
        ScoringsRegistry scoringRegistry = ScoringsRegistry(migrationHost);

        require(_startIndex + _count <= scoringRegistry.getScoringsAmount());        

        for (uint i = _startIndex; i < _startIndex + _count; i++) {
            address scoringAddress = scoringRegistry.getScoringAddressByIndex(i);
            uint scoringId = scoringRegistry.getScoringIdByIndex(i);         

            addScoringInternal(scoringAddress, scoringId, scoringRegistry.getScoringAreas(scoringId));

            for (uint areaIndex = 0; areaIndex < scoringRegistry.getScoringAreas(scoringId).length; areaIndex++) {
                uint area = scoringRegistry.getScoringAreas(scoringId)[areaIndex];

                setVacantExpertPositionCountInternal(scoringId, area, scoringRegistry.getVacantExpertPositionCounts(scoringId, area));

                for (uint offerIndex = 0; offerIndex < scoringRegistry.getOffers(scoringId, area).length; offerIndex++) {
                    address offer = scoringRegistry.getOffers(scoringId, area)[offerIndex];
                    uint state = scoringRegistry.getOfferState(scoringId, area, offer);    
                    addOfferInternal(scoringId, area, offer);              
                    setOfferStateInternal(scoringId, area, offer, state);
                }
            }
        }
    }   
}