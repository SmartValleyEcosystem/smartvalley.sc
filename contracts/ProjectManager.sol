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
    address scoringAddress;

    function ProjectManager(address _svtAddress, uint _projectCreationCost, uint _estimateReward, address _scoringAddress) public {
        setTokenAddress(_svtAddress);
        setProjectCreationCost(_projectCreationCost);
        setEstimateReward(_estimateReward);
        setScoringAddress(_scoringAddress);
    }

    function addProject(uint256 _externalId, string _name) external {
        require(svt.balanceOf(msg.sender) >= projectCreationCostWEI);
        Project project = new Project(msg.sender, _name, svt, estimateRewardWEI, scoringAddress);
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

    function setScoringAddress(address _scoringAddress) public onlyOwner {
        require(_scoringAddress != 0);
        scoringAddress = _scoringAddress;
    }

    function updateProjectsScoringAddress(uint startIndex, uint count) public onlyOwner {
        require(startIndex + count <= projects.length);

        for (var i = startIndex; i < startIndex + count; i++) {
            var project = Project(projects[i]);
            project.setScoringAddress(scoringAddress);
        }
    }
}
