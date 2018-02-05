module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    development: {
      host: "localhost",
      port: 9545,
      network_id: "*", // Match any network id
      gasPrice: 1000000000
    },
    rinkeby: {
      host: "94.130.173.102",      
      port: 8545,
      network_id: 4,
      from: "0xcF50BfCccA03D45b7caE212C6b928FF5718DCb7e"      
    }
  }
};
