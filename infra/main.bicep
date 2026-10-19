@description('Azure region')
param location string = 'japaneast'

@description('AKS cluster name')
param aksName string = 'aks-juiceshop-demo'

@description('AKS node VM size')
param nodeVmSize string = 'Standard_D2as_v5'

// ACR name must be globally unique and alphanumeric only
var acrName = toLower('acr${uniqueString(resourceGroup().id)}juice')

// AcrPull built-in role
var acrPullRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '7f951dda-4ed3-4680-a7ca-43fe172d538d'
)

//
// Azure Container Registry
//
resource acr 'Microsoft.ContainerRegistry/registries@2025-04-01' = {
  name: acrName
  location: location

  sku: {
    name: 'Basic'
  }

  properties: {
    adminUserEnabled: false
    anonymousPullEnabled: false
    publicNetworkAccess: 'Enabled'
  }

  tags: {
    Environment: 'Demo'
    Application: 'OWASP-Juice-Shop'
    Purpose: 'Code-to-Cloud-Security'
  }
}

//
// Azure Kubernetes Service
//
resource aks 'Microsoft.ContainerService/managedClusters@2026-02-01' = {
  name: aksName
  location: location

  sku: {
    name: 'Base'
    tier: 'Free'
  }

  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    dnsPrefix: aksName

    enableRBAC: true

    agentPoolProfiles: [
      {
        name: 'system'
        count: 1
        vmSize: nodeVmSize
        osType: 'Linux'
        osDiskType: 'Managed'
        mode: 'System'
        type: 'VirtualMachineScaleSets'
        enableNodePublicIP: false
      }
    ]

    networkProfile: {
      networkPlugin: 'azure'
      networkPluginMode: 'overlay'
      loadBalancerSku: 'standard'
      outboundType: 'loadBalancer'
    }
  }

  tags: {
    Environment: 'Demo'
    Application: 'OWASP-Juice-Shop'
    Purpose: 'Code-to-Cloud-Security'
  }
}

//
// Allow AKS kubelet identity to pull images from ACR
//
resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, aks.id, acrPullRoleDefinitionId)
  scope: acr

  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: aks.properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
  }
}

//
// Outputs
//
output acrName string = acr.name
output acrLoginServer string = acr.properties.loginServer
output aksName string = aks.name
