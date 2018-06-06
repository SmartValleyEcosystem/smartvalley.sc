pragma solidity ^ 0.4.24;

import "./Scoring.sol";

contract PrivateScoring is Scoring {

    constructor(address _scoringParametersProviderAddress) Scoring(_scoringParametersProviderAddress) public {
    }

    function removeEstimates(address _expertAddress, uint _area) external {
        Estimate[] storage areaEstimates = estimates[_area];
        for (uint i = 0; i < areaEstimates.length; i++) {
            if (areaEstimates[i].expertAddress == _expertAddress) {
                delete areaEstimates[i];

                if (i != areaEstimates.length - 1) {
                    areaEstimates[i] = areaEstimates[areaEstimates.length - 1];
                }

                i--;
                areaEstimates.length--;
            }
        }
    }

    function getReward(uint _area) private view returns(uint) {
        return 0;
    }
}