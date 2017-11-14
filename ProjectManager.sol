pragma solidity ^ 0.4.13;

import "./Owned.sol";
import "./Project.sol";

contract ProjectManager is Owned {

    address[] public projects;

    function addProject(address _creator, string _applicationHash, string _name) external returns(address) {
        Project project = new Project(_creator, _applicationHash, _name);
        projects.push(project);
        return project;
    }
}
