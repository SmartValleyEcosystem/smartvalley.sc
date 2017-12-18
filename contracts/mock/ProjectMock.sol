pragma solidity ^ 0.4.18;

import "../Project.sol";

contract ProjectMock is Project {
    function ProjectMock(address _svtAddress, address _scoringAddress) Project (0x0, "mock", _svtAddress, 10 * (10 ** 18), _scoringAddress) public {
    }
}