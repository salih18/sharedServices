az network application-gateway waf-policy managed-rule exclusion add \
    --match-variable RequestHeaderNames \
    --policy-name $policyName \
    --resource-group $resourceGroupName \
    --selector-match-operator Contains \
    --selector "User-Agent" 

az network application-gateway waf-policy managed-rule exclusion add \
    --match-variable RequestHeaderNames \
    --policy-name $policyName \
    --resource-group $resourceGroupName \
    --selector-match-operator Contains \
    --selector "User" 

az network application-gateway waf-policy managed-rule exclusion add \
    --match-variable RequestHeaderNames \
    --policy-name $policyName \
    --resource-group $resourceGroupName \
    --selector-match-operator Contains \
    --selector "Test" 

    addExclusion() {
    local selector="$1"
    az network application-gateway waf-policy managed-rule exclusion add \
        --match-variable RequestHeaderNames \
        --policy-name "$policyName" \
        --resource-group "$resourceGroupName" \
        --selector-match-operator Contains \
        --selector "$selector"
}

addExclusion "User-Agent"
addExclusion "User"
addExclusion "Test"


selectors=(${selectors//,/ })

# Loop over the selectors parameter and call addExclusion() for each selector
for selector in "${selectors[@]}"
do
    echo "$selector"
done



- task: AzurePowerShell@5
  inputs:
    azureSubscription: '<Your-Azure-Service-Connection>'
    ScriptType: 'InlineScript'
    Inline: |
      $vnetName = "your_vnet_name"
      $resourceGroup = "your_resource_group"
      $subnets = @("subnet1", "subnet2")

      foreach($subnet in $subnets) {
        $serviceEndpoints = az network vnet subnet show --resource-group $resourceGroup --vnet-name $vnetName --name $subnet --query 'serviceEndpoints[].provisioningState' -o tsv
        if ($serviceEndpoints -contains "Succeeded") {
            Write-Output "Service endpoints in subnet $subnet are enabled."
        } else {
            Write-Output "Service endpoints in subnet $subnet are not enabled."
        }
      }
    azurePowerShellVersion: 'LatestVersion'
