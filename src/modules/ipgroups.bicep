param config object
param location string = resourceGroup().location

var shortLocation = config.regionPrefixLookup[location]

resource ipgAzureVnets 'Microsoft.Network/ipGroups@2021-05-01' = {
  name: '${shortLocation}-azureVnets'
  location: location
  properties: {
    ipAddresses: [
      '10.1.0.0/16'
      '10.50.0.0/16'
    ]
  }
}

resource ipgOnPremSubnets 'Microsoft.Network/ipGroups@2021-05-01' = {
  name: '${shortLocation}-onpremSubnets'
  location: location
  properties: {
    ipAddresses: [
      '192.168.0.0/16'
    ]
  }
  dependsOn: [
    ipgAzureVnets
  ]
}

output ipgIdAzureVnets string = ipgAzureVnets.id
output ipgIdOnPremSubnets string = ipgOnPremSubnets.id
