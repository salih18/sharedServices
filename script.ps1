# Creating an array of Azure Resource Manager service connections in JSON format
$jsonServiceConnections = @"
[
    {
        "Id": "12345",
        "Name": "SampleConnection1",
        "Type": "AzureResourceManager",
        "Description": "This is a sample Azure Resource Manager service connection",
        "ServicePrincipalId": "abcde-12345-abcde",
        "TenantId": "12345-abcde-12345",
        "SubscriptionId": "abcde-12345-abcde"
    },
    {
        "Id": "67890",
        "Name": "SampleConnection2",
        "Type": "AzureResourceManager",
        "Description": "This is a sample Azure Resource Manager service connection",
        "ServicePrincipalId": "fghij-67890-fghij",
        "TenantId": "67890-fghij-67890",
        "SubscriptionId": "fghij-67890-fghij"
    },
    {
        "Id": "11123",
        "Name": "SampleConnection3",
        "Type": "AzureResourceManager",
        "Description": "This is a sample Azure Resource Manager service connection",
        "ServicePrincipalId": "klmno-11123-klmno",
        "TenantId": "11123-klmno-11123",
        "SubscriptionId": "klmno-11123-klmno"
    }
]
"@

# Convert JSON to PowerShell objects
$serviceConnections = $jsonServiceConnections | ConvertFrom-Json

# Iterate over the service connections
foreach ($serviceConnection in $serviceConnections) {
    # Print each service connection
    Write-Output $serviceConnection.Name
}
