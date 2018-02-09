pragma solidity ^ 0.4.18;

import "./Owned.sol";
import "./ExpertsRegistry.sol";

contract ExpertsSelector is Owned {

    ExpertsRegistry private expertsRegistry;

    function ExpertsSelector(address _expertsRegistryAddress) public {
        setExpertsRegistryAddress(_expertsRegistryAddress);
    }

    function setExpertsRegistryAddress(address _value) public onlyOwner {
        require(_value != 0);
        expertsRegistry = ExpertsRegistry(_value);
    }

    function select(uint _expertsCount, uint _area) external view returns(address[]) {
        require(_expertsCount > 0);

        var expertsCountInArea = expertsRegistry.getExpertsCountInArea(_area);
        if (expertsCountInArea <= _expertsCount) {
            return getAllExpertsInArea(_area, expertsCountInArea);
        }

        return getRandomExpertsInArea(_area, _expertsCount, expertsCountInArea);
    }

    function getAllExpertsInArea(uint _area, uint _count) private view returns(address[]) {
        address[] memory result = new address[](_count);
        for (uint i = 0; i < _count; i++) {
            result[i] = expertsRegistry.areaExpertsMap(_area, i);
        }
        return result;
    }

    function getRandomExpertsInArea(uint _area, uint _count, uint _totalExpertsCount) private view returns(address[]) {
        uint indexMapSegmentSize = 256;
        uint[] memory indexMap = new uint[]((_totalExpertsCount / indexMapSegmentSize) + 1);
        address[] memory result = new address[](_count);
        uint someNumber = 0;
        for (uint i = 0; i < _count; i++) {
            someNumber = getRandomNumber(someNumber + i, _totalExpertsCount);
            var expertIndex = adjustIndex(someNumber, indexMap, indexMapSegmentSize, _totalExpertsCount);
            result[i] = expertsRegistry.areaExpertsMap(_area, expertIndex);
        }
        return result;
    }

    function adjustIndex(uint _index, uint[] _map, uint _mapSegmentSize, uint _count) private pure returns(uint) {
        uint mapSegmentIndex = _index / _mapSegmentSize;
        uint numberPosition = 2 ** (_index % _mapSegmentSize);

        if (_map[mapSegmentIndex] & numberPosition == numberPosition) {
            var nextNumber = getNextIndex(_index, _count);
            return adjustIndex(nextNumber, _map, _mapSegmentSize, _count);
        } else {
            _map[mapSegmentIndex] |= numberPosition;
            return _index;
        }
    }

    function getRandomNumber(uint _seed, uint _maximum) private view returns(uint) {
        return uint(keccak256(uint(block.blockhash(block.number - _seed - 1)), _seed)) % _maximum;
    }

    function getNextIndex(uint _index, uint _count) private pure returns(uint) {
        if (_index < _count - 1) {
            return _index + 1;
        } else {
            return 0;
        }
    }
}