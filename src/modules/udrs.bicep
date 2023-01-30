param config object
param onlySpokeTemplates bool = false
param location string = resourceGroup().location

var shortLocation = config.regionPrefixLookup[location]

// Determine which firewall to use from config
var routeTableNextHopLookup = {
  afw: config.hub.azureFirewallSubnet.lbIpAddress
  nva: config.hub.nvaInternalSubnet.lbIpAddress
}
var routeTableNextHopIpAddress = routeTableNextHopLookup[config.routeTableNextHop]

// Use the information provided so far to determine route table entries
var routesDefault = [
  {
    name: 'default'
    properties: {
      addressPrefix: '0.0.0.0/0'
      nextHopType: 'VirtualAppliance'
      nextHopIpAddress: routeTableNextHopIpAddress
    }
  }
]
var routesHubVmSubnets = [for destinationSubnet in config.hub._routeViaNva: {
  name: 'to-${toUpper(config.hub.name)}-${toUpper(config.hub[destinationSubnet].name)}-subnet'
  properties: {
    addressPrefix: config.hub[destinationSubnet].prefix
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: routeTableNextHopIpAddress
  }
}]
var routesSpokeVnets = [for destinationVnet in config.spokes._routeViaNva: {
  name: 'to-${toUpper(config.spokes[destinationVnet].name)}-vnet'
  properties: {
    addressPrefix: config.spokes[destinationVnet].prefix
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: routeTableNextHopIpAddress
  }
}]

// Create hub route tables
resource rt_hubVnetGatewaySubnet 'Microsoft.Network/routeTables@2021-02-01' = if (!onlySpokeTemplates) {
  location: location
  name: '${shortLocation}-hub-GatewaySubnet-rt'
  properties: {
    disableBgpRoutePropagation: false // must be false for the GatewaySubnet
    routes: concat(routesSpokeVnets, routesHubVmSubnets) // define all routes except for 'default'
  }
}

var filteredRoutes1 = [for route in routesHubVmSubnets: (route.properties.addressPrefix != config.hub.vmSubnet1.prefix) ? route : routesDefault[0]]
resource rt_hubVnetVmSubnet1 'Microsoft.Network/routeTables@2021-02-01' = if (!onlySpokeTemplates) {
  location: location
  name: '${shortLocation}-hub-${config.hub.vmSubnet1.name}-rt'
  properties: {
    disableBgpRoutePropagation: true // must be true
    routes: union(concat(routesSpokeVnets, filteredRoutes1), routesDefault) // define all routes except for its own subnet 
  }
}

var filteredRoutes2 = [for route in routesHubVmSubnets: (route.properties.addressPrefix != config.hub.vmSubnet2.prefix) ? route : routesDefault[0]]
resource rt_hubVnetVmSubnet2 'Microsoft.Network/routeTables@2021-02-01' = if (!onlySpokeTemplates) {
  location: location
  name: '${shortLocation}-hub-${config.hub.vmSubnet2.name}-rt'
  properties: {
    disableBgpRoutePropagation: true // must be true
    routes: union(concat(routesSpokeVnets, filteredRoutes2), routesDefault) // define all routes except for its own subnet
  }
}

// Create a template route table for spokes
resource rt_spokeTemplate 'Microsoft.Network/routeTables@2021-02-01' = {
  location: location
  name: '${shortLocation}-spoke-vnet-rt'
  properties: {
    disableBgpRoutePropagation: true // must be true
    routes: concat(routesDefault, routesHubVmSubnets) // only need to define 'default' route and any vm subnets in the hub
  }
}

output rtId_hubVnetGatewaySubnet string = rt_hubVnetGatewaySubnet.id
output rtId_hubVnetVmSubnet1 string = rt_hubVnetVmSubnet1.id
output rtId_hubVnetVmSubnet2 string = rt_hubVnetVmSubnet2.id
output rtId_spokeTemplate string = rt_spokeTemplate.id
