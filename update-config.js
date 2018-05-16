const fs = require('fs')

/*
Example
- go to truffle root dir
- in cmd or ps console type (%args% - optional):
node .\update-config.js %args%
    args:
        1 - network id
        2 - path to appsettings.json
*/

//default path to appsettings.json
let configPath = 'C:\\Users\\User\\Documents\\smartvalley\\SmartValley.WebApi\\appsettings.json'
//default network id from truffle config
//4 - rinkeby
//4447 - privatnet truffle develop
let network_id = '4'

let mock = true

if (process.argv.length > 2) {
    network_id = process.argv[2]    
}

if (process.argv.length > 3) {
    configPath = process.argv[3]
}

try {
    let appsettings = JSON.parse(fs.readFileSync(configPath, 'utf-8').trim())    

    const contracts = [
        {name: 'EtherManager', config: appsettings.NethereumOptions.EtherManagerContract, deployable: true},
        {name: 'SmartValleyToken', config: appsettings.NethereumOptions.TokenContract, deployable: true},
        {name: 'Minter', config: appsettings.NethereumOptions.MinterContract, deployable: true},
        {name: 'ScoringManager', config: appsettings.NethereumOptions.ScoringManagerContract, deployable: true},
        {name: 'AdministratorsRegistry', config: appsettings.NethereumOptions.AdminRegistryContract, deployable: true},
        {name: 'Scoring', config: appsettings.NethereumOptions.ScoringContract, deployable: false},
      ]
      
      for (let i = 0; i < contracts.length; i++) {
          let source = JSON.parse(fs.readFileSync('./build/contracts/' + contracts[i].name + (mock ? 'Mock' : '') + '.json'))
          let result = ''
          if(contracts[i].deployable) {
            const address = source.networks[network_id].address
            contracts[i].config.Address = address
            result += ' address ' + address + ' and'
          }
          
          const abi = JSON.stringify(source.abi)          
          contracts[i].config.Abi = abi
          console.log(contracts[i].name + result + ' abi added in ' + configPath)
          
      }
      
      fs.writeFileSync(configPath, JSON.stringify(appsettings, null, 2))
      
      console.log(configPath + ' successful updated')

} catch (err) {    
    console.error(err)    
}