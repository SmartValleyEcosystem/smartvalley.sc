pragma solidity ^ 0.4.18;

import "./Owned.sol";
import "./SmartValleyToken.sol";

contract Minter is Owned {

    uint public constant DAYS_INTERVAL_BETWEEN_RECEIVE = 3;

    uint256 public amountToGift = 1200;
    mapping(address => uint) public receiversDateMap;
    SmartValleyToken public token;
    address public scoringManagerAddress;

    function Minter(address _tokenAddress, address _scoringManagerAddress) public {
        setTokenAddress(_tokenAddress);
        setScoringManagerAddress(_scoringManagerAddress);
    }

    modifier onlyScoringManager {
        require(msg.sender == scoringManagerAddress);
        _;
    }


    function getTokens() external {
        require(canGetTokens(msg.sender));
        token.mintTokens(msg.sender, amountToGift * (10 ** uint(token.decimals())));
        receiversDateMap[msg.sender] = now;
    }

    function mintTokens(address _to, uint256 _amount) external onlyScoringManager {
        token.mintTokens(_to, _amount);
    }

    function canGetTokens(address _receiverAddress) view public returns(bool) {
        require(_receiverAddress != address(0));
        return receiversDateMap[_receiverAddress] == 0 || now - receiversDateMap[_receiverAddress] >= DAYS_INTERVAL_BETWEEN_RECEIVE * 1 days;
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(0));
        token = SmartValleyToken(_tokenAddress);
    }

    function setScoringManagerAddress(address _scoringManagerAddress) public onlyOwner {
        require(_scoringManagerAddress != address(0));
        scoringManagerAddress = _scoringManagerAddress;
    }

    function setAmountToGift(uint256 _amountToGift) external onlyOwner {
        require(_amountToGift > 0);
        amountToGift = _amountToGift;
    }
}