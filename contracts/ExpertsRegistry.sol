pragma solidity ^ 0.4.24;

import "./Owned.sol";
import "./AdministratorsRegistry.sol";
import "./ScoringParametersProvider.sol";

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

    mapping(uint => address[]) public expertsByAreaMap;
    mapping(address => Expert) public expertsMap;
    Application[] public applications;
    address public migrationHostAddress;

    AdministratorsRegistry private administratorsRegistry;
    ScoringParametersProvider public scoringParametersProvider;

    constructor(address _administratorsRegistryAddress, address _scoringParametersProviderAddress) public {
        setAdministratorsRegistry(_administratorsRegistryAddress);
        setScoringParametersProvider(_scoringParametersProviderAddress);
    }

    modifier onlyAdministrators {
        require(administratorsRegistry.isAdministrator(msg.sender));
        _;
    }

    function setAdministratorsRegistry(address _address) public onlyOwner {
        require(_address != 0);
        administratorsRegistry = AdministratorsRegistry(_address);
    }

    function setScoringParametersProvider(address _address) public onlyOwner {
        require(_address != 0);
        scoringParametersProvider = ScoringParametersProvider(_address);
    }

    function setMigrationHost(address _address) external onlyOwner {
        require(_address != 0);
        migrationHostAddress = _address;
    }

    function apply(uint[] _areas, bytes32 applicationHash) external {
        require(_areas.length > 0 && applicationHash.length > 0);

        expertsMap[msg.sender].applicationHash = applicationHash;

        for (uint i = 0; i < _areas.length; i++) {
            uint area = _areas[i];
            require(scoringParametersProvider.doesAreaExist(area));
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

        uint[] memory areas = scoringParametersProvider.getAreas();
        for (uint i = 0; i < areas.length; i++) {
            uint area = areas[i];

            require(!expertsMap[_expert].areas[area].approved);
            expertsMap[_expert].areas[area].applied = false;
        }

        removeApplications(_expert);
    }

    function enable(address _expert) external {
        require(administratorsRegistry.isAdministrator(msg.sender) || msg.sender == _expert);
        require(expertsMap[_expert].exists && !expertsMap[_expert].enabled);

        expertsMap[_expert].enabled = true;

        uint[] memory areas = scoringParametersProvider.getAreas();
        for (uint i = 0; i < areas.length; i++) {
            uint area = areas[i];
            if (expertsMap[_expert].areas[area].approved) {
                addInArea(_expert, area);
            }
        }
    }

    function disable(address _expert) external {
        require(expertsMap[_expert].exists);
        require(administratorsRegistry.isAdministrator(msg.sender) || msg.sender == _expert);

        uint[] memory areas = scoringParametersProvider.getAreas();
        for (uint i = 0; i < areas.length; i++) {
            uint area = areas[i];
            if (expertsMap[_expert].areas[area].approved) {
                removeFromAreaCollection(expertsMap[_expert].areas[area].index, area);
            }
        }

        expertsMap[_expert].enabled = false;
    }

    function add(address _expert, uint[] _areas) public onlyAdministrators {
        require(_areas.length > 0 && _expert != 0);

        for (uint i = 0; i < _areas.length; i++) {
            addInternal(_expert, _areas[i]);
        }
    }

    function remove(address _expert) external onlyAdministrators {
        require(expertsMap[_expert].exists);

        uint[] memory areas = scoringParametersProvider.getAreas();
        for (uint i = 0; i < areas.length; i++) {
            uint area = areas[i];
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

    function getExpertsCountInArea(uint _area) external view returns(uint) {
        return expertsByAreaMap[_area].length;
    }

    function getExpertsIndices(uint _area, address[] _experts) external view returns(uint[]) {
        uint[] memory result = new uint[](_experts.length);
        for (uint i = 0; i < _experts.length; i++) {
            result[i] = expertsMap[_experts[i]].areas[_area].index;
        }
        return result;
    }

    function getExpertsInArea(uint _area) external view returns(address[]) {
        return expertsByAreaMap[_area];
    }

    function getApplicationHash(address _expert) external view returns(bytes32) {
        return expertsMap[_expert].applicationHash;
    }

    function addInternal(address _expert, uint _area) private {
        if (!expertsMap[_expert].exists) {
            expertsMap[_expert].exists = true;
        }

        require(!expertsMap[_expert].areas[_area].approved);

        addInArea(_expert, _area);
    }

    function isApproved(address _expert, uint _area) external view returns(bool) {
        return expertsMap[_expert].areas[_area].approved;
    }

    function setApplicationHash(address _expert, bytes32 _hash) private {
        expertsMap[_expert].applicationHash = _hash;
    }

    function removeFromAreaCollection(uint _index, uint _area) private {
        address[] storage expertsInArea = expertsByAreaMap[_area];
        require(expertsInArea.length > 0);

        address expertToMove = expertsInArea[expertsInArea.length - 1];
        expertsInArea[_index] = expertToMove;

        if (_index != expertsInArea.length - 1) {
            expertsMap[expertToMove].areas[_area].index = _index;
        }

        expertsInArea.length--;
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
        expertsByAreaMap[_area].push(_expert);
        expertsMap[_expert].areas[_area].approved = true;
        expertsMap[_expert].areas[_area].index = expertsByAreaMap[_area].length - 1;
        expertsMap[_expert].enabled = true;
    }
}
