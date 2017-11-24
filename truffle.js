module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      gasPrice: 1,
      network_id: "*" // Match any network id
    },
    rinkeby: {
      host: "localhost",
      port: 8545,
      network_id: "4",      
      gasPrice: 1,
      from: '0xcda3753490ce49535600d7299222b8493fe0d810'
    }
  }
};
