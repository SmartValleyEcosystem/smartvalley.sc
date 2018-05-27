pragma solidity ^ 0.4.24;

library RandomGenerator {

    uint constant MAP_SEGMENT_SIZE = 256;

    function generate(uint _count, uint _ceiling, uint[] _numbersToExclude, uint _seed) internal view returns(uint[]) {
        require(_count > 0 && _count <= _ceiling - _numbersToExclude.length);

        uint[] memory uniquenessMap = new uint[]((_ceiling / MAP_SEGMENT_SIZE) + 1);

        if (_numbersToExclude.length != 0)
            addToMap(uniquenessMap, _numbersToExclude);

        uint[] memory result = new uint[](_count);
        for (uint i = 0; i < _count; i++) {
            uint seed = i == 0 ? _seed : result[i - 1] + i;
            result[i] = getUniqueNumber(seed, _ceiling, uniquenessMap);
        }
        return result;
    }

    function getUniqueNumber(uint _seed, uint _ceiling, uint[] _uniquenessMap) private view returns(uint) {
        uint number = getSomeNumber(_seed, _ceiling);
        return ensureUnique(number, _ceiling, _uniquenessMap);
    }

    function getSomeNumber(uint _seed, uint _ceiling) private view returns(uint) {
        return uint(keccak256(abi.encodePacked(uint(blockhash(block.number - 1)), _seed))) % _ceiling;
    }

    function ensureUnique(uint _number, uint _ceiling, uint[] _uniquenessMap) private pure returns(uint) {
        uint mapSegmentIndex = _number / MAP_SEGMENT_SIZE;
        uint numberPositionInMapSegment = 2 ** (_number % MAP_SEGMENT_SIZE);

        if (_uniquenessMap[mapSegmentIndex] & numberPositionInMapSegment == 0) {
            _uniquenessMap[mapSegmentIndex] |= numberPositionInMapSegment;
            return _number;
        } else {
            uint nextNumber = _number < _ceiling - 1 ? _number + 1 : 0;
            return ensureUnique(nextNumber, _ceiling, _uniquenessMap);
        }
    }

    function addToMap(uint[] _uniquenessMap, uint[] _numbers) private pure {
        for (uint i = 0; i < _numbers.length; i++) {
            uint number = _numbers[i];
            uint mapSegmentIndex = number / MAP_SEGMENT_SIZE;
            uint numberPositionInMapSegment = 2 ** (number % MAP_SEGMENT_SIZE);

            _uniquenessMap[mapSegmentIndex] |= numberPositionInMapSegment;
        }
    }
}
