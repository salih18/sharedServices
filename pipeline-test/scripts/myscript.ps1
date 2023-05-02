param(
    [Parameter(Mandatory=$true)]
    [string]$Arg1,
    [Parameter(Mandatory=$true)]
    [string]$Arg2,
    [Parameter(Mandatory=$true)]
    [string]$Arg3
    )
    
Write-Host "Hello World"
Write-Host "Arg1: $Arg1"
Write-Host "Arg2: $Arg2"
Write-Host "Arg3: $Arg3"