pragma solidity ^ 0.4.18;
import "../Contracts/KnownContractInterface.sol";

contract KnownContractMock is KnownContract {
    
    address public transferedSender;
    uint256 public transferedValue;
    bytes32[] public transferedData;
    
    uint256 public callCount = 0;
    
    function KnownContractMock() public {}
    
    function transfered(address _sender, uint256 _value, bytes32[] _data) external {
        transferedSender = _sender;
        transferedValue += _value;
        transferedData = _data;
        
        callCount++;
    }
}