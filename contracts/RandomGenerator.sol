pragma solidity ^ 0.4.19;

library RandomGenerator {

    uint constant MAP_SEGMENT_SIZE = 256;
    uint constant MAXIMUM_COUNT = 20;

    function generate(uint _count, uint _ceiling) internal view returns(uint[]) {
        require(_count > 0 && _count <= MAXIMUM_COUNT);

        uint[] memory uniquenessMap = new uint[]((_ceiling / MAP_SEGMENT_SIZE) + 1);

        var result = new uint[](_count);
        for (uint i = 0; i < _count; i++) {
            uint seed = i == 0 ? 0 : result[i - 1] + i;
            result[i] = getUniqueNumber(seed, _ceiling, uniquenessMap);
        }
        return result;
    }

    function getUniqueNumber(uint _seed, uint _ceiling, uint[] _uniquenessMap) private view returns(uint) {
        var number = getSomeNumber(_seed, _ceiling);
        return ensureUnique(number, _ceiling, _uniquenessMap);
    }

    function getSomeNumber(uint _seed, uint _ceiling) private view returns(uint) {
        return uint(keccak256(uint(block.blockhash(block.number - _seed - 1)), _seed)) % _ceiling;
    }

    function ensureUnique(uint _number, uint _ceiling, uint[] _uniquenessMap) private pure returns(uint) {
        uint mapSegmentIndex = _number / MAP_SEGMENT_SIZE;
        uint numberPositionInMapSegment = 2 ** (_number % MAP_SEGMENT_SIZE);

        if (_uniquenessMap[mapSegmentIndex] & numberPositionInMapSegment != 0) {
            var nextNumber = _number < _ceiling - 1 ? _number + 1 : 0;
            return ensureUnique(nextNumber, _ceiling, _uniquenessMap);
        } else {
            _uniquenessMap[mapSegmentIndex] |= numberPositionInMapSegment;
            return _number;
        }
    }
}
