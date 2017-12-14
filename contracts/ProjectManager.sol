pragma solidity ^ 0.4.18;

import "./Owned.sol";
import "./Project.sol";
import "./SmartValleyToken.sol";

contract ProjectManager is Owned {

    address[] public projects;
    mapping(uint256 => address) public projectsMap;
    SmartValleyToken public svt;
    uint public projectCreationCostWEI;
    uint public estimateRewardWEI;

   function ProjectManager(address _svtAddress, uint _projectCreationCost, uint _estimateReward) public {       
       setTokenAddress(_svtAddress);
       setProjectCreationCost(_projectCreationCost);
       setEstimateReward(_estimateReward);
    }

    function addProject(uint256 _externalId, string _name) external {    
        require(svt.balanceOf(msg.sender) >= projectCreationCostWEI);
        Project project = new Project(msg.sender, _name, svt, estimateRewardWEI);
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

    function setEstimateReward(uint _estimateReward) public onlyOwner {
        estimateRewardWEI = _estimateReward * (10 ** uint(svt.decimals()));
    }
}
