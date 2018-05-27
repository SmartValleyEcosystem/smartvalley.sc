pragma solidity ^ 0.4.24;

import "./Owned.sol";

contract AdministratorsRegistry is Owned {

    mapping(address => bool) public administratorsMap;

    constructor() public {
        administratorsMap[msg.sender] = true;
    }

    modifier onlyAdministrators {
        require(msg.sender == owner || administratorsMap[msg.sender]);
        _;
    }

    function add(address _user) external onlyAdministrators {
        require(_user != 0, "user address cannot be 0");
        administratorsMap[_user] = true;
    }

    function remove(address _user) external onlyAdministrators {
        require(_user != 0, "user address cannot be 0");
        administratorsMap[_user] = false;
    }

    function isAdministrator(address _user) external view returns (bool) {
        require(_user != 0, "user address cannot be 0");
        return administratorsMap[_user];
    }
}
