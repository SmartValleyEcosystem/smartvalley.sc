pragma solidity ^ 0.4.24;

library SafeMath {
    uint256 constant public MAX_UINT256 = ~uint(0);

    function add(uint256 x, uint256 y) pure internal returns(uint256) {
        if (x > MAX_UINT256 - y) {
            revert();
        }

        return x + y;
    }

    function sub(uint256 x, uint256 y) pure internal returns(uint256) {
        if (x < y) {
            revert();
        }

        return x - y;
    }

    function multiply(uint256 x, uint256 y) pure internal returns(uint256) {
        if (y == 0) {
            return 0;
        }

        if (x > MAX_UINT256 / y) {
            revert();
        }

        return x * y;
    }
}