pragma solidity ^ 0.4.24;

library ContractExtensions {
    function isContract(address _address) internal view returns(bool) {
        if (_address == 0) {
            return false;
        }

        uint codeSize;
        assembly { codeSize := extcodesize(_address) }

        return codeSize > 0;
    }
}