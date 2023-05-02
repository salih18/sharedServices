policyName=$1
resourceGroupName=$2

echo policyName: $policyName
echo resourceGroupName: $resourceGroupName

selectors=(${selectors//,/ })

# Loop over the selectors parameter and call addExclusion() for each selector
for selector in "${selectors[@]}"
do
    echo "$selector"
done