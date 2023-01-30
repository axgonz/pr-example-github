param config object
param location string = resourceGroup().location
param firewallPublicIpAddress string

var shortLocation = config.regionPrefixLookup[location]
var name = 'pol-main'

module ipgs 'ipgroups.bicep' = {
  name: '${shortLocation}-${name}-ipgs'
  params: {
    config: config
    location: location
  }
}

resource polMain 'Microsoft.Network/firewallPolicies@2021-05-01' = {
  name: '${shortLocation}-${name}'
  location: location
  properties: {
     sku: {
       tier: 'Standard'
     }
     threatIntelMode: 'Alert'
     threatIntelWhitelist: {
       fqdns: []
       ipAddresses: []
     }
  }
  dependsOn: [
    ipgs
  ]  
}

resource rcgDnat 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2021-05-01' = {
  name: 'DefaultDnatRuleCollectionGroup'
  parent: polMain
  properties: {
    priority: 100
    ruleCollections: [
      {
        name: 'website'
        priority: 1000
        ruleCollectionType: 'FirewallPolicyNatRuleCollection'
        action: {
          type: 'DNAT'
        }
        rules: [
          {
            ruleType: 'NatRule'
            name: 'port80bind'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: [
              firewallPublicIpAddress
            ]
            destinationPorts: [
              '80'
            ]
            translatedAddress: '10.1.43.4'
            translatedPort: '80'
          }         
        ]
      }
    ]
  }
}

resource rcgNetwork 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2021-05-01' = {
  name: 'DefaultNetworkRuleCollectionGroup'
  parent: polMain
  properties: {
    priority: 200
    ruleCollections: [
      {
        name: 'basic'
        priority: 1000
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'azure-TO-onprem'
            ipProtocols: [
              'Any'
            ]
            sourceIpGroups: [
              ipgs.outputs.ipgIdAzureVnets
            ]
            destinationIpGroups: [
              ipgs.outputs.ipgIdOnPremSubnets
            ]
            destinationPorts: [
              '*'
            ]
          }
          {
            ruleType: 'NetworkRule'
            name: 'onprem-TO-azure'
            ipProtocols: [
              'Any'
            ]
            sourceIpGroups: [
              ipgs.outputs.ipgIdOnPremSubnets
            ]
            destinationIpGroups: [
              ipgs.outputs.ipgIdAzureVnets
            ]
            destinationPorts: [
              '*'
            ]
          }          
        ]
      }
    ]
  }
  dependsOn: [
    rcgDnat
  ]
}

resource rcgApplication 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2021-05-01' = {
  name: 'DefaultApplicationRuleCollectionGroup'
  parent: polMain
  properties: {
    priority: 300
    ruleCollections: [
      {
        name: 'SafeSites'
        priority: 1000
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'github'
            protocols: [
              {
                protocolType: 'Http'
                port: 80
              }
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            terminateTLS: false
            sourceIpGroups: [
              '${ipgs.outputs.ipgIdAzureVnets}'
            ]
            targetFqdns: [
              '*.github.com'
            ]
          }
        ]
      }
    ]
  }
  dependsOn: [
    rcgNetwork
  ]
}

output polIdMain string = polMain.id
