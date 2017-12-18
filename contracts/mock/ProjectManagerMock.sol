pragma solidity ^ 0.4.18;

import "../ProjectManager.sol";

contract ProjectManagerMock  is ProjectManager {  
    
    function ProjectManagerMock (address _svtAddress, uint _projectCreationCost) ProjectManager (_svtAddress, _projectCreationCost) public {
    }
}