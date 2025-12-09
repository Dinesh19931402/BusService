@description('Location for AKS and ACR')
param location string = resourceGroup().location

@description('AKS cluster name')
param aksName string = 'DineshDemo'

@description('DNS prefix for AKS API server')
param dnsPrefix string = 'dineshdemo'

@description('Node count for default pool')
param nodeCount int = 2

@description('VM size for nodes')
param nodeVmSize string = 'Standard_DS2_v2'

@description('AKS System Node Pool Name')
param nodePoolName string = 'dineshdemonodepool'

@description('ACR Name')
param acrName string = 'dineshdemoacr'

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: acrName
}

resource aks 'Microsoft.ContainerService/managedClusters@2024-01-01' = {
  name: aksName
  location: location
  sku: {
    name: 'Base'
    tier: 'Free'
  }
  properties: {
    dnsPrefix: dnsPrefix
    kubernetesVersion: ''  // latest
    enableRBAC: true
    agentPoolProfiles: [
      {
        name: nodePoolName
        count: nodeCount
        vmSize: nodeVmSize
        osType: 'Linux'
        mode: 'System'
        type: 'VirtualMachineScaleSets'
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
      outboundType: 'loadBalancer'
    }
    identity: {
      type: 'SystemAssigned'
    }
  }
}

@description('Grant AKS pull access to ACR')
resource acrRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aks.id, acr.id, 'AcrPull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull
    )
    principalId: aks.identityProfile['kubeletidentity'].objectId
    principalType: 'ServicePrincipal'
  }
}
