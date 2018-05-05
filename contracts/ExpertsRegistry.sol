pragma solidity ^ 0.4.22;

import "./Owned.sol";
import "./AdministratorsRegistry.sol";

contract ExpertsRegistry is Owned {
    struct Expert {
        bool exists;
        bool enabled;
        mapping(uint => ExpertArea) areas;
        bytes32 applicationHash;
    }

    struct ExpertArea {
        bool applied;
        bool approved;
        uint index;
    }

    struct Application {
        address expert;
        uint area;        
    }

    mapping(uint => address[]) public areaExpertsMap;
    mapping(address => Expert) public expertsMap;
    Application[] public applications;
    uint[] public availableAreas;    
    address public migrationHost;

    AdministratorsRegistry private administratorsRegistry;

    constructor (address _administratorsRegistryAddress, uint[] _areas) public {
        setAdministratorsRegistry(_administratorsRegistryAddress);
        setAvailableAreas(_areas);
    }

    modifier onlyAdministrators {
        require(administratorsRegistry.isAdministrator(msg.sender));
        _;
    }

    function setAdministratorsRegistry(address _administratorsRegistryAddress) public onlyOwner {
        require(_administratorsRegistryAddress != 0);
        administratorsRegistry = AdministratorsRegistry(_administratorsRegistryAddress);    
    }
    
    function setMigrationHost(address _address) external onlyOwner {
        require(_address != 0);
        migrationHost = _address;
    }

    function setAvailableAreas(uint[] _areas) public onlyOwner {
        availableAreas = _areas;
    }

    function apply(uint[] _areas, bytes32 applicationHash) external {
        require(_areas.length > 0 && applicationHash.length > 0);

        expertsMap[msg.sender].applicationHash = applicationHash;
        
        for (uint i = 0; i < _areas.length; i++) {
            uint area = _areas[i];
            require(!expertsMap[msg.sender].areas[area].approved);

            expertsMap[msg.sender].areas[area].applied = true;           
            applications.push(Application(msg.sender, area));
        }
    }

    function approve(address _expert, uint[] _areas) external onlyAdministrators {
        require(_areas.length > 0 && _expert != 0);

        for (uint i = 0; i < _areas.length; i++) {
            uint area = _areas[i];

            require(expertsMap[_expert].areas[area].applied);
            require(!expertsMap[_expert].areas[area].approved);

            addInArea(_expert, area);
        }

        removeApplications(_expert);
        expertsMap[_expert].exists = true;
    }

    function reject(address _expert) external onlyAdministrators {
        require(_expert != 0);

        for (uint i = 0; i < availableAreas.length; i++) {
            uint area = availableAreas[i];
            if (expertsMap[_expert].areas[area].applied)
                expertsMap[_expert].areas[area].applied = false;
        }

        removeApplications(_expert);
    }

    function enable(address _expert) external {
        require(administratorsRegistry.isAdministrator(msg.sender) || msg.sender == _expert);
        require(expertsMap[_expert].exists && !expertsMap[_expert].enabled);

        expertsMap[_expert].enabled = true;

        for (uint i = 0; i < availableAreas.length; i++) {
            uint area = availableAreas[i];
            if (expertsMap[_expert].areas[area].approved) {
                addInArea(_expert, area);
            }
        }
    }

    function disable(address _expert) external {
        require(expertsMap[_expert].exists);
        require(administratorsRegistry.isAdministrator(msg.sender) || msg.sender == _expert);

        for (uint i = 0; i < availableAreas.length; i++) {
            uint area = availableAreas[i];
            if (expertsMap[_expert].areas[area].approved) {
                removeFromAreaCollection(expertsMap[_expert].areas[area].index, area);
            }
        }

        expertsMap[_expert].enabled = false;
    }

    function add(address _expert, uint[] _areas) external onlyAdministrators {
        addInternal(_expert, _areas);
    }

    function addInternal(address _expert, uint[] _areas) private {
        expertsMap[_expert].exists = true;

        for (uint i = 0; i < _areas.length; i++) {
            require(!expertsMap[_expert].areas[_areas[i]].approved);
            addInArea(_expert, _areas[i]);
        }
    }

    function remove(address _expert) external onlyAdministrators {
        require(expertsMap[_expert].exists);

        for (uint i = 0; i < availableAreas.length; i++) {
            uint area = availableAreas[i];
            if (expertsMap[_expert].areas[area].approved) {
                removeFromAreaCollection(expertsMap[_expert].areas[area].index, area);
                expertsMap[_expert].areas[area].approved = false;
            }
        }

        expertsMap[_expert].enabled = false;
        expertsMap[_expert].exists = false;
    }

    function removeInArea(address _expert, uint _area) external onlyAdministrators {
        require(expertsMap[_expert].areas[_area].approved);

        removeFromAreaCollection(expertsMap[_expert].areas[_area].index, _area);
        expertsMap[_expert].areas[_area].approved = false;
    }

    function getApplications() external view returns(address[] _experts, uint[] _areas) {
        uint[] memory areas = new uint[](applications.length);
        address[] memory experts = new address[](applications.length);

        for (uint i = 0; i < applications.length; i++) {
            Application memory application = applications[i];

            experts[i] = application.expert;
            areas[i] = application.area;
        }

        _experts = experts;
        _areas = areas;
    }

    function migrateFromMigrationHost (uint _startIndex, uint _count, uint _area) external onlyOwner {
        require(migrationHost != 0);
        ExpertsRegistry expertsRegistry = ExpertsRegistry(migrationHost); 
        require(_startIndex + _count <= expertsRegistry.getExpertsCountInArea(_area));     

        address[] memory experts = expertsRegistry.getExpertsInArea(_area);

        for (uint i = _startIndex; i < _startIndex + _count; i++) {             
             address expert = experts[i];         
             uint[] memory areas = new uint[](1);    
             areas[0] = _area;
             addInternal(expert, areas);
             expertsMap[expert].exists = true;
             bytes32 applicationHash = expertsRegistry.getApplicationHash(expert);
             setApplicationHash(expert, applicationHash);
          }
     }
    

    function getExpertsCountInArea(uint _area) external view returns(uint) {
        return areaExpertsMap[_area].length;
    }

    function getExpertsInArea(uint _area) public view returns(address[]) {
        return areaExpertsMap[_area];
    }

    function getExpertIndex(address _expert, uint _area) external view returns(uint) {
        return expertsMap[_expert].areas[_area].index;
    }

    function getApplicationHash(address _expert) public view returns(bytes32) {
        return expertsMap[_expert].applicationHash;
    }

    function setApplicationHash(address _expert, bytes32 _hash) private {
        expertsMap[_expert].applicationHash = _hash;
    }

    function removeFromAreaCollection(uint _index, uint _area) private {
        address[] storage areaCollection = areaExpertsMap[_area];
        address expertToMove = areaCollection[areaCollection.length - 1];
        areaCollection[_index] = expertToMove;

        if (_index != areaCollection.length - 1) {
            expertsMap[expertToMove].areas[_area].index = _index;
        }

        areaCollection.length--;
    }

    function removeApplications(address _expert) private {
        for (uint i = 0; i < applications.length; i++) {
            if (applications[i].expert == _expert) {
                delete(applications[i]);

                if (i < applications.length - 1) {
                    applications[i] = applications[applications.length - 1];
                }

                applications.length--;
                i--;
            }
        }
    }

    function addInArea(address _expert, uint _area) private {
        areaExpertsMap[_area].push(_expert);
        expertsMap[_expert].areas[_area].approved = true;
        expertsMap[_expert].areas[_area].index = areaExpertsMap[_area].length - 1;
        expertsMap[_expert].enabled = true;
    }
}
