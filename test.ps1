param (
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$ApplicationGatewayName
)

$variable1 = New-AzApplicationGatewayFirewallMatchVariable -VariableName RequestUri
$condition1 = New-AzApplicationGatewayFirewallCondition -MatchVariable $variable1 -Operator Contains -MatchValue @("test1", "test2") -NegationCondition $false
$customRule1 = New-AzApplicationGatewayFirewallCustomRule -Name "Rule1Allow" -Priority 20 -RuleType MatchRule-MatchConditions $condition1  -Action Allow 

$variable2 = New-AzApplicationGatewayFirewallMatchVariable -VariableName RequestHeaders -Selector "User-Agent"
$condition2 = New-AzApplicationGatewayFirewallCondition -MatchVariable $variable2 -Operator Contains -MatchValue "bots" -Transform Lowercase -NegationCondition $false
$customRule2 = New-AzApplicationGatewayFirewallCustomRule -Name "blockBots" -Priority 10 -RuleType MatchRule -MatchConditions $condition2 -Action Block

$policySettingGlobal = New-AzApplicationGatewayFirewallPolicySetting -State Enabled -Mode Prevention
$customWafPolicy = New-AzApplicationGatewayFirewallPolicy -Name "myCustomWafPolicy-$ResourceGroupName" -ResourceGroupName $ResourceGroupName -Location "westeurope" -PolicySetting $policySettingGlobal -CustomRule $customRule1, $customRule2 -Force

$appGateway = Get-AzApplicationGateway -Name $ApplicationGatewayName -ResourceGroupName $ResourceGroupName
Set-AzApplicationGatewayFirewallPolicy -InputObject $customWafPolicy
$appGateway.FirewallPolicy = $customWafPolicy
$appGateway.ForceFirewallPolicyAssociation = $true
Set-AzApplicationGateway -ApplicationGateway $appGateway
