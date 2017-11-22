pragma solidity ^ 0.4.13;

import "./Owned.sol";
import "./Project.sol";

contract ProjectManager is Owned {

    address[] public projects;
    mapping(uint256 => address) public projectsMap;

    function addProject(uint256 _externalId, string _name) external {
        Project project = new Project(msg.sender, _name);
        projects.push(project);
        projectsMap[_externalId] = project;
    }
}
