pragma solidity ^ 0.4.13;

import "./Owned.sol";
import "./Project.sol";

contract ProjectManager is Owned {

    address[] public projects;
    mapping(uint256 => address) public projectsMap;

    function addProject(uint _id, address _author, string _name) external {
        Project project = new Project(_author, _name);
        projects.push(project);
        projectsMap[_id] = project;
    }
}
