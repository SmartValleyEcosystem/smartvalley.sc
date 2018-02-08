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

if (process.argv.length > 2) {
    network_id = process.argv[2]    
}

if (process.argv.length > 3) {
    configPath = process.argv[3]
}

try {
    let appsettings = JSON.parse(fs.readFileSync(configPath, 'utf-8').trim())    

    const contracts = [
        {name: 'EtherManager', config: appsettings.NethereumOptions.EtherManagerContract},
        {name: 'SmartValleyToken', config: appsettings.NethereumOptions.TokenContract},
        {name: 'VotingManager', config: appsettings.NethereumOptions.VotingManagerContract},
        {name: 'Minter', config: appsettings.NethereumOptions.MinterContract},
        {name: 'ScoringManager', config: appsettings.NethereumOptions.ScoringManagerContract},
      ]
      
      for (let i = 0; i < contracts.length; i++) {
          let source = JSON.parse(fs.readFileSync('./build/contracts/' + contracts[i].name + '.json'))
          let address = source.networks[network_id].address
          contracts[i].config.Address = address
          console.log(contracts[i].name + ' address ' + address + ' added in appsetings.json')
      }
      
      fs.writeFileSync(configPath, JSON.stringify(appsettings, null, 2))
      
      console.log('appsettings.json successful updated')

} catch (err) {    
    console.error(err)    
}