targetScope = 'subscription'

// ----------------------------------------
// Parameter declaration
@description('Azure region for deployment')
param location string

@description('Dictionary of deployment regions with shortname')
param locationList object

@description('Environment for deployment')
param env string

@description('Gets the current date in the format below. Do not Change!')
param currentDate string = utcNow('yyyy-MM-dd')

@description('Application component being deployed')
param component string

@description('Application being deployed')
param product string

@description('Resource group properties')
param resourceGroupProperties object

@description('Properties for deploying action group')
param actionGroupProperties object

@description('Properties of Logs Workspace deployment')
param workspaceProperties object

@description('Properties for deploying application insights')
param applicationInsightProperties object

@description('Properties for vnet')
param vnetProperties object

@description('Properties for keyvault deployment')
param keyVaultProperties object 

// ----------------------------------------
// Variable declaration

var locationShortName = locationList[location] // Shortname of Azure region for deployment
var groupName = '${product}-${component}' // Name of the resource group
var environmentName = '${groupName}-${env}-${locationShortName}' // Name of the environment
var resourceGroupName = 'rg-${environmentName}' // Name of the resource group deployment
var actionGroupName = 'ag-${product}-${component}-${locationShortName}' // Name of the action group
var actionGroupShortName = '${substring(product, 0, 2)}${component}${env}' // Shortname of the action group
var workspaceName = 'log-${environmentName}' // Name of the logs workspace
var appInsightsName = 'appi-${environmentName}' // Name of the application insights
var appInsightsDiagName = 'diag-appi-${environmentName}' // Name of the diagnostic settings for Application Insights
var vnetName = 'vnet-${groupName}-${env}-${locationShortName}' // Name of the virtual network
var vnetDiagName = 'diag-vnet-${environmentName}' // Name of the diagnostic settings for Virtual Network
var keyVaultName = 'kv${product}${component}${env}${locationShortName}' // Name of the keyvault
var keyvaultDiagName = 'diag-kv-${environmentName}' // Name of the diagnostic settings for KeyVault
var frontDoorName = 'fd${product}${component}${env}${locationShortName}' // Name of the frontdoor
var frontDoorDiagName = 'diag-fd-${environmentName}' // Name of the diagnostic settings for FrontDoor

// Resource Properties
var ipRules = loadJsonContent('../Configuration/devops_services_ips.json') // Load json content for devops service IPs
var weuIpRules = ipRules.euwest.ip_addresses // IP addresses for Western Europe region
var allowedKeyvaultVirtualNetworks = keyVaultProperties.allowedSubnets // Allowed subnets for KeyVault

var tagValues = {
  createdBy: 'Az CLI'
  environment: env
  deploymentDate: currentDate
  product: product
}

module sharedServicesResourceGroup './modules/Microsoft.Resources/resourceGroups/deploy.bicep' = {
  name: resourceGroupName
  params: {
    name: resourceGroupName
    location: location
    tags: tagValues
    lock: 'CanNotDelete'
    roleAssignments: resourceGroupProperties.roleAssignments
  }
}

module sharedServicesActionGroup './modules/Microsoft.Insights/actionGroups/deploy.bicep' = {
  scope: resourceGroup(sharedServicesResourceGroup.name)
  name: '${actionGroupName}-${environmentName}-dp'

  params: {
    // Required parameters
    location: 'global'
    groupShortName: actionGroupShortName
    name: actionGroupName
    // Non-required parameters
    emailReceivers: actionGroupProperties.emailReceivers
    enableDefaultTelemetry: true
    roleAssignments: actionGroupProperties.roleAssignments
    armRoleReceivers: actionGroupProperties.armRoleReceivers
  }
}

module sharedServicesLogAnalytics './modules/Microsoft.OperationalInsights/workspaces/deploy.bicep' = {
  scope: resourceGroup(sharedServicesResourceGroup.name)
  name: 'log-${environmentName}-dp'
  params: {
    // Required parameters
    location: location
    name: workspaceName
    // Non-required parameters
    enableDefaultTelemetry: true
    dataRetention: workspaceProperties.retentionInDays
    serviceTier: workspaceProperties.skuName    
  }
}

module sharedServicesApplicationInsights './modules/Microsoft.Insights/components/deploy.bicep' = {
  scope: resourceGroup(sharedServicesResourceGroup.name)
  name: 'appi-${environmentName}-dp'
  params: {
    location: location
    // Required parameters
    name: appInsightsName
    workspaceResourceId: sharedServicesLogAnalytics.outputs.resourceId
    // Non-required parameters
    enableDefaultTelemetry: true
    applicationType: 'web'
    kind: 'web'
    roleAssignments: applicationInsightProperties.roleAssignments
    diagnosticSettingsName: appInsightsDiagName
    diagnosticWorkspaceId: sharedServicesLogAnalytics.outputs.resourceId
    diagnosticLogCategoriesToEnable: applicationInsightProperties.diagnostics.logs
    diagnosticLogsRetentionInDays: 30
    diagnosticMetricsToEnable:  applicationInsightProperties.diagnostics.metrics
  }
}

module sharedServicesVnet './modules/Microsoft.Network/virtualNetworks/deploy.bicep' = {
  scope:resourceGroup(sharedServicesResourceGroup.name)
  name: 'vnet-${environmentName}-dp'
  params: {
    location: location
    // Required parameters
    addressPrefixes: vnetProperties.addressPrefixes
    name: vnetName
    // Non-required parameters
    dnsServers: vnetProperties.dnsServers
    enableDefaultTelemetry: true
    lock: 'CanNotDelete'
    roleAssignments: vnetProperties.roleAssignments
    subnets: vnetProperties.subnets
    env: env
    locationShortName: locationShortName

    diagnosticSettingsName: vnetDiagName
    diagnosticWorkspaceId: sharedServicesLogAnalytics.outputs.resourceId
    diagnosticLogCategoriesToEnable: vnetProperties.diagnostics.logs
    diagnosticLogsRetentionInDays: 30
    diagnosticMetricsToEnable:  vnetProperties.diagnostics.metrics
  }
}

module sharedServicesKeyVault './modules/Microsoft.KeyVault/vaults/deploy.bicep' = {
  scope: resourceGroup(sharedServicesResourceGroup.name)
  name: '${keyVaultName}-dp'
  params: {
    name: keyVaultName
    location: location
    lock: 'CanNotDelete'
    vaultSku: keyVaultProperties.sku
    enableDefaultTelemetry: true

    enableVaultForDeployment: keyVaultProperties.enabledForDeployment
    enableVaultForTemplateDeployment: keyVaultProperties.enabledForTemplateDeployment
    enableVaultForDiskEncryption: keyVaultProperties.enabledForDiskEncryption
    enableRbacAuthorization: keyVaultProperties.enableRbacAuthorization
    enableSoftDelete: keyVaultProperties.enableSoftDelete
    softDeleteRetentionInDays: keyVaultProperties.softDeleteRetentionInDays
    enablePurgeProtection: keyVaultProperties.enablePurgeProtection

    roleAssignments: keyVaultProperties.roleAssignments

    diagnosticSettingsName: keyvaultDiagName
    diagnosticWorkspaceId: sharedServicesLogAnalytics.outputs.resourceId
    diagnosticLogCategoriesToEnable: keyVaultProperties.diagnostics.logs
    diagnosticLogsRetentionInDays: keyVaultProperties.metricsRetentionDays
    diagnosticMetricsToEnable:  keyVaultProperties.diagnostics.metrics
    
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: [ for vnet in allowedKeyvaultVirtualNetworks: {
        id: '${sharedServicesVnet.outputs.resourceId}/subnets/snet-${vnet}-${env}-${locationShortName}'
        ignoreMissingVnetServiceEndpoint: false
      }]
      ipRules: weuIpRules
  }

  }
}

// module frontDoors './modules/Microsoft.Network/frontDoors/deploy.bicep' = {
//   scope: resourceGroup(sharedServicesResourceGroup.name)
//   name: '${frontDoorName}-dp'
//   params: {
//     // Required parameters
//     location: location
//     backendPools: [
//       {
//         name: 'backendPool'
//         properties: {
//           backends: [
//             {
//               address: 'biceptest.local'
//               backendHostHeader: 'backendAddress'
//               enabledState: 'Enabled'
//               httpPort: 80
//               httpsPort: 443
//               priority: 1
//               privateLinkAlias: ''
//               privateLinkApprovalMessage: ''
//               privateLinkLocation: ''
//               privateLinkResourceId: ''
//               weight: 50
//             }
//           ]
//           HealthProbeSettings: {
//             id: '<id>'
//           }
//           LoadBalancingSettings: {
//             id: '<id>'
//           }
//         }
//       }
//     ]
//     frontendEndpoints: [
//       {
//         name: 'frontEnd'
//         properties: {
//           hostName: '<hostName>'
//           sessionAffinityEnabledState: 'Disabled'
//           sessionAffinityTtlSeconds: 60
//         }
//       }
//     ]
//     healthProbeSettings: [
//       {
//         name: 'heathProbe'
//         properties: {
//           enabledState: ''
//           healthProbeMethod: ''
//           intervalInSeconds: 60
//           path: '/'
//           protocol: 'Https'
//         }
//       }
//     ]
//     loadBalancingSettings: [
//       {
//         name: 'loadBalancer'
//         properties: {
//           additionalLatencyMilliseconds: 0
//           sampleSize: 50
//           successfulSamplesRequired: 1
//         }
//       }
//     ]
//     name: '<name>'
//     routingRules: [
//       {
//         name: 'routingRule'
//         properties: {
//           acceptedProtocols: [
//             'Http'
//             'Https'
//           ]
//           enabledState: 'Enabled'
//           frontendEndpoints: [
//             {
//               id: '<id>'
//             }
//           ]
//           patternsToMatch: [
//             '/*'
//           ]
//           routeConfiguration: {
//             '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
//             backendPool: {
//               id: '<id>'
//             }
//             forwardingProtocol: 'MatchRequest'
//           }
//         }
//       }
//     ]
//     // Non-required parameters
//     enableDefaultTelemetry: '<enableDefaultTelemetry>'
//     enforceCertificateNameCheck: 'Disabled'
//     lock: 'CanNotDelete'
//     roleAssignments: [
//       {
//         principalIds: [
//           '<managedIdentityPrincipalId>'
//         ]
//         principalType: 'ServicePrincipal'
//         roleDefinitionIdOrName: 'Reader'
//       }
//     ]
//     sendRecvTimeoutSeconds: 10
//     tags: {
//       Environment: 'Non-Prod'
//       Role: 'DeploymentValidation'
//     }
//   }
// }


