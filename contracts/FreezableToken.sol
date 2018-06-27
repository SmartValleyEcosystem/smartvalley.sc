pragma solidity ^ 0.4.24;

import "./StandardToken.sol";
import "./FreezableTokenTarget.sol";
import "./ContractExtensions.sol";

contract FreezableToken is StandardToken {
    using ContractExtensions for address;

    mapping(address => Freezing[]) public freezingsMap;

    struct Freezing {
        uint amount;
        uint endTimestamp;
        address target;
    }

    function freeze(uint _amount, address _target) external {
        require(msg.sender != 0 && _amount > 0);
        require(_target.isContract());

        removeExpiredFreezings(msg.sender);

        FreezableTokenTarget target = FreezableTokenTarget(_target);

        uint duration = target.getFreezingDuration();
        require(duration > 0);

        Freezing memory freezing = Freezing(_amount, now + duration, _target);
        freezingsMap[msg.sender].push(freezing);

        target.frozen(msg.sender, _amount);
    }

    function unfreeze(address _account) external {
        Freezing[] storage freezings = freezingsMap[_account];
        for (uint i = 0; i < freezings.length; i++) {
            if (freezings[i].target == msg.sender) {
                freezings[i] = freezings[freezings.length - 1];
                freezings.length --;
                i--;
            }
        }
    }

    function getFrozenAmount(address _account) public view returns (uint _result) {
        Freezing[] memory freezings = freezingsMap[_account];
        for (uint i = 0; i < freezings.length; i++) {
            if (freezings[i].endTimestamp > now) {
                _result += freezings[i].amount;
            }
        }
    }

    function getFreezingDetails(address _account) external view returns(uint[] _amounts, uint[] _endTimestamps, address[] _targets) {
        Freezing[] memory freezings = freezingsMap[_account];

        _amounts = new uint[](freezings.length);
        _endTimestamps = new uint[](freezings.length);
        _targets = new address[](freezings.length);

        for (uint i = 0; i < freezings.length; i++) {
            _amounts[i] = freezings[i].amount;
            _endTimestamps[i] = freezings[i].endTimestamp;
            _targets[i] = freezings[i].target;
        }
    }

    function removeExpiredFreezings(address _account) private {
        Freezing[] storage freezings = freezingsMap[_account];
        for (uint i = 0; i < freezings.length; i++) {
            if (freezings[i].endTimestamp <= now) {
                freezings[i] = freezings[freezings.length - 1];
                freezings.length --;
                i--;
            }
        }
    }
}
