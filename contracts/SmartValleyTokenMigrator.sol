pragma solidity ^ 0.4.24;

import "./MigrationAgent.sol";

contract SmartValleyTokenMigrator {
    function migrate(address _tokenHolder, address _to, uint256 _amount) public {
        MigrationAgent agent = MigrationAgent(_to);
        
        agent.migrateFrom(_tokenHolder, _amount);
    }
}