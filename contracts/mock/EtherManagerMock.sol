pragma solidity ^ 0.4.22;

import "../EtherManager.sol";

contract EtherManagerMock is EtherManager {

    constructor() public payable {}

    function removeReceiver(address _receiver) public {
        uint i = 0;
        for (i = 0; i < receivers.length; i++) {
            if (receivers[i] == _receiver) { 
                break; 
            }
        }
        delete receivers[i];
        delete receiversMap[_receiver];
    }
}