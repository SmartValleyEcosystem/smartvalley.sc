pragma solidity ^ 0.4.13;

import "./Owned.sol";

contract Project is Owned {

    address public author;
    string public name;

    function Project(address _author, string _name) public {
        author = _author;
        name = _name;
    }
}
