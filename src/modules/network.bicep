// Resource declaration in Bicep
// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/resource-declaration

param config object
param onlySpokeTemplates bool = false
param location string = resourceGroup().location

module nsgs 'nsgs.bicep' = {
  name: '${deployment().name}-nsgs'
  params: {
    config: config
    location: location
    onlySpokeTemplates: onlySpokeTemplates  
  }
}

module udrs 'udrs.bicep' = {
  name: '${deployment().name}-udrs'
  params: {
    config: config
    location: location
    onlySpokeTemplates: onlySpokeTemplates
  }
}

// Create hub virtual network
resource vnet_hub 'Microsoft.Network/virtualNetworks@2021-02-01' = if (!onlySpokeTemplates) {
  location: location
  name: '${config.hub.name}'
  properties: {
    addressSpace: {
      addressPrefixes: [
        config.hub.prefix
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: config.hub.gatewaySubnet.prefix
          routeTable: {
            id: udrs.outputs.rtId_hubVnetGatewaySubnet
          }
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: config.hub.azureFirewallSubnet.prefix
        }
      }
      {
        name: 'AzureFirewallManagementSubnet'
        properties: {
          addressPrefix: config.hub.azureFirewallManagementSubnet.prefix
        }
      }
      {
        name: config.hub.nvaManagementSubnet.name
        properties: {
          addressPrefix: config.hub.nvaManagementSubnet.prefix
          networkSecurityGroup: {
            id: nsgs.outputs.nsgId_hubVnetNvaSubnetManagement
          }
        }
      }
      {
        name: config.hub.nvaDiagnosticSubnet.name
        properties: {
          addressPrefix: config.hub.nvaDiagnosticSubnet.prefix
          networkSecurityGroup: {
            id: nsgs.outputs.nsgId_hubVnetNvaSubnetDiagnostic
          }
        }
      }
      {
        name: config.hub.nvaInternalSubnet.name
        properties: {
          addressPrefix: config.hub.nvaInternalSubnet.prefix
          networkSecurityGroup: {
            id: nsgs.outputs.nsgId_hubVnetNvaSubnetInternal
          }
        }
      }
      {
        name: config.hub.nvaPublicSubnet.name
        properties: {
          addressPrefix: config.hub.nvaPublicSubnet.prefix
          networkSecurityGroup: {
            id: nsgs.outputs.nsgId_hubVnetNvaSubnetPublic
          }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: config.hub.azureBastionSubnet.prefix
        }
      }
      {
        name: 'RouteServerSubnet'
        properties: {
          addressPrefix: config.hub.routeServerSubnet.prefix
        }
      }
      {
        name: config.hub.applicationGatewaySubnet1.name
        properties: {
          addressPrefix: config.hub.applicationGatewaySubnet1.prefix
        }
      }
      {
        name: config.hub.applicationGatewaySubnet2.name
        properties: {
          addressPrefix: config.hub.applicationGatewaySubnet2.prefix
        }
      }
      {
        name: config.hub.applicationGatewaySubnet3.name
        properties: {
          addressPrefix: config.hub.applicationGatewaySubnet3.prefix
        }
      }
      {
        name: config.hub.vmSubnet1.name
        properties: {
          addressPrefix: config.hub.vmSubnet1.prefix
          networkSecurityGroup: {
            id: nsgs.outputs.nsgId_hubVnetVmSubnet1
          }
          routeTable: {
            id: udrs.outputs.rtId_hubVnetVmSubnet1
          }
        }
      }
      {
        name: config.hub.vmSubnet2.name
        properties: {
          addressPrefix: config.hub.vmSubnet2.prefix
          networkSecurityGroup: {
            id: nsgs.outputs.nsgId_hubVnetVmSubnet2
          }
          routeTable: {
            id: udrs.outputs.rtId_hubVnetVmSubnet2
          }
        }
      }
    ]
  }
}

output vnetId_hub string = vnet_hub.id
