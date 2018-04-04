pragma solidity ^ 0.4.18;

import "./Owned.sol";

contract AdministratorsRegistry is Owned {

    mapping(address => bool) public administratorsMap;

    modifier onlyAdministrators {
        require(msg.sender == owner || administratorsMap[msg.sender]);
        _;
    }

    function add(address _user) external onlyAdministrators {
        require(_user != 0);
        administratorsMap[_user] = true;
    }

    function remove(address _user) external onlyAdministrators {
        require(_user != 0);
        administratorsMap[_user] = false;
    }

    function isAdministrator(address _user) external view returns (bool) {
        require(_user != 0);
        return administratorsMap[_user];
    }
}
