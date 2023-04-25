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



