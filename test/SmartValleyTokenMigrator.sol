 pragma solidity ^ 0.4.22;

import "../contracts/MigrationAgentInterface.sol";

contract SmartValleyTokenMigrator {
    function migrate(address _tokenHolder, address _to, uint256 _amount) public {
        MigrationAgent agent = MigrationAgent(_to);
        
        agent.migrateFrom(_tokenHolder, _amount);
    }
}