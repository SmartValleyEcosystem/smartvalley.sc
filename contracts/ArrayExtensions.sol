pragma solidity ^ 0.4.24;

library ArrayExtensions {
    function indexOf(uint[] _array, uint _item) external pure returns(uint) {
        for (uint i = 0; i < _array.length; i++) {
            if (_array[i] == _item) {
                return i;
            }
        }
        return uint(-1);
    }

    function distinct(uint[] _array) external pure returns(uint[]) {
        require(_array.length <= 256);

        if (_array.length < 2) {
            return _array;
        }

        uint map = 0;
        uint max = _array[0];
        uint uniqueElementsCount = 0;
        for (uint i = 0; i < _array.length; i++) {
            if (map & 2 ** _array[i] == 0) {
                map |= 2 ** _array[i];
                uniqueElementsCount++;

                if (_array[i] > max) {
                    max = _array[i];
                }
            }
        }

        uint[] memory result = new uint[](uniqueElementsCount);
        uint resultIndex = 0;
        for (uint j = 0; j <= max; j++) {
            if (map & 2 ** j != 0) {
                result[resultIndex] = j;
                resultIndex++;
            }
        }

        return result;
    }

    function contains(uint[] _array, uint _item) external pure returns(bool) {
        for (uint i = 0; i < _array.length; i++) {
            if (_array[i] == _item) {
                return true;
            }
        }
        return false;
    }

    function remove(address[] storage _array, address _item) external {
        for (uint i = 0; i < _array.length; i++) {
            if (_array[i] == _item) {
                delete _array[i];

                if(i != _array.length - 1) {
                    _array[i] = _array[_array.length - 1];
                }

                _array.length--;
                return;
            }
        }
    }
}