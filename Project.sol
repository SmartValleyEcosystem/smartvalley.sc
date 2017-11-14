pragma solidity ^ 0.4.13;

import "./Owned.sol";

contract Project is Owned {

    address public creator;
    string public applicationHash;
    string public name;

    function Project(address _creator, string _applicationHash, string _name) public {
        creator = _creator;
        applicationHash = _applicationHash;
        name = _name;
    }
}
