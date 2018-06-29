pragma solidity ^ 0.4.24;

import "./Owned.sol";
import "./SmartValleyToken.sol";

contract Minter is Owned {

    uint public receiveInterval;
    uint256 public tokenAmount;
    mapping(address => uint) public receiveTimestampsMap;
    SmartValleyToken public token;

    constructor(address _tokenAddress, uint _receiveIntervalDays, uint _tokenAmount) public {
        setTokenAddress(_tokenAddress);
        setReceiveIntervalDays(_receiveIntervalDays);
        setTokenAmount(_tokenAmount);
    }

    function getTokens() external {
        require(canGetTokens(msg.sender));

        token.mint(msg.sender, tokenAmount * (10 ** uint(token.decimals())));
        receiveTimestampsMap[msg.sender] = now;
    }

    function canGetTokens(address _receiver) view public returns(bool) {
        require(_receiver != 0);

        uint receiveTimestamp = receiveTimestampsMap[_receiver];
        return receiveTimestamp == 0 || now - receiveTimestamp >= receiveInterval;
    }

    function setTokenAddress(address _value) public onlyOwner {
        require(_value != 0);

        token = SmartValleyToken(_value);
    }

    function setTokenAmount(uint256 _value) public onlyOwner {
        require(_value > 0);

        tokenAmount = _value;
    }

    function setReceiveIntervalDays(uint256 _value) public onlyOwner {
        require(_value > 0);

        receiveInterval = _value * 1 days;
    }
}