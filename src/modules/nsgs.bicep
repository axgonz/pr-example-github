param config object
param onlySpokeTemplates bool = false
param location string = resourceGroup().location

var shortLocation = config.regionPrefixLookup[location]

// Create hub network security groups
resource nsg_hubVnetNvaSubnetManagement 'Microsoft.Network/networkSecurityGroups@2021-02-01' = if (!onlySpokeTemplates) {
  location: location
  name: '${shortLocation}-hub-${config.hub.nvaManagementSubnet.name}-nsg'
}
resource nsg_hubVnetNvaSubnetDiagnostic 'Microsoft.Network/networkSecurityGroups@2021-02-01' = if (!onlySpokeTemplates) {
  location: location
  name: '${shortLocation}-hub-${config.hub.nvaDiagnosticSubnet.name}-nsg'
}
resource nsg_hubVnetNvaSubnetInternal 'Microsoft.Network/networkSecurityGroups@2021-02-01' = if (!onlySpokeTemplates) {
  location: location
  name: '${shortLocation}-hub-${config.hub.nvaInternalSubnet.name}-nsg'
  properties: {
    securityRules: [
      {
        name: 'Allow-Inbound-RFC1918'
        properties: {
          direction: 'Inbound'
          access: 'Allow'
          priority: 1000
          protocol: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          sourceAddressPrefixes: [
            '10.0.0.0/8'
            '172.16.0.0/12'
            '192.168.0.0/16'
          ]
          sourcePortRange: '*'
        }
      }
    ]
  }
}
resource nsg_hubVnetNvaSubnetPublic 'Microsoft.Network/networkSecurityGroups@2021-02-01' = if (!onlySpokeTemplates) {
  location: location
  name: '${shortLocation}-hub-${config.hub.nvaPublicSubnet.name}-nsg'
  properties: {
    securityRules: [
      {
        name: 'Allow-Inbound-All'
        properties: {
          direction: 'Inbound'
          access: 'Allow'
          priority: 1000
          protocol: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
    ]
  }
}
resource nsg_hubVnetVmSubnet1 'Microsoft.Network/networkSecurityGroups@2021-02-01' = if (!onlySpokeTemplates) {
  location: location
  name: '${shortLocation}-hub-${config.hub.vmSubnet1.name}-nsg'
}
resource nsg_hubVnetVmSubnet2 'Microsoft.Network/networkSecurityGroups@2021-02-01' = if (!onlySpokeTemplates) {
  location: location
  name: '${shortLocation}-hub-${config.hub.vmSubnet2.name}-nsg'
}

// Create a template network security group for spokes
resource nsg_spokeTemplate 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  location: location
  name: '${shortLocation}-spoke-vnet-nsg'
}

output nsgId_hubVnetNvaSubnetManagement string = nsg_hubVnetNvaSubnetManagement.id
output nsgId_hubVnetNvaSubnetDiagnostic string = nsg_hubVnetNvaSubnetDiagnostic.id
output nsgId_hubVnetNvaSubnetInternal string = nsg_hubVnetNvaSubnetInternal.id
output nsgId_hubVnetNvaSubnetPublic string = nsg_hubVnetNvaSubnetPublic.id
output nsgId_hubVnetVmSubnet1 string = nsg_hubVnetVmSubnet1.id
output nsgId_hubVnetVmSubnet2 string = nsg_hubVnetVmSubnet2.id
output nsgId_spokeTemplate string = nsg_spokeTemplate.id
