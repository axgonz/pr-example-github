param config object
param location string = resourceGroup().location

var shortLocation = config.regionPrefixLookup[location]
var name = 'firewall'

resource vnetHub 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: '${config.hub.name}'
}

resource ipFirewall 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: '${shortLocation}-${name}-ip'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

module fwPols 'fwpolicy.bicep' = {
  name: '${shortLocation}-${name}-policies'
  params: {
    config: config
    location: location
    firewallPublicIpAddress: ipFirewall.properties.ipAddress
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2021-05-01' = {
  name: '${shortLocation}-${name}'
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          publicIPAddress: {
            id: ipFirewall.id
          }
          subnet: {
            id: '${vnetHub.id}/subnets/AzureFirewallSubnet'
          }
        }
      }
    ]
    firewallPolicy: {
      id: fwPols.outputs.polIdMain
    }
  }
}
