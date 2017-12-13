pragma solidity ^ 0.4.18;

import "./Owned.sol";
import "./Project.sol";
import "./SmartValleyToken.sol";

contract ProjectManager is Owned {

    address[] public projects;
    mapping(uint256 => address) public projectsMap;
    SmartValleyToken public svt;
    uint public projectCreationCostWEI;

   function ProjectManager(address _svtAddress, uint _projectCreationCost) public {       
       setTokenAddress(_svtAddress);
       setProjectCreationCost(_projectCreationCost);
    }

    function addProject(uint256 _externalId, string _name) external {    
        require(svt.balanceOf(msg.sender) >= projectCreationCostWEI);
        Project project = new Project(msg.sender, _name);
        projects.push(project);
        projectsMap[_externalId] = project;
        svt.transferFromOrigin(project, projectCreationCostWEI);
    }

    function setTokenAddress(address _svtAddress) public onlyOwner {
        require(_svtAddress != 0);
        svt = SmartValleyToken(_svtAddress);
    }

    function setProjectCreationCost(uint _projectCreationCost) public onlyOwner {
        projectCreationCostWEI = _projectCreationCost * (10 ** uint(svt.decimals()));
    }
}
