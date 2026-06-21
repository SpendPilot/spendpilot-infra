param(
    [ValidateSet("init", "workspace", "plan", "apply")]
    [string]$Action = "plan",

    [switch]$AutoApprove,

    [switch]$BuildImagesDuringApply
)

$ErrorActionPreference = "Stop"
$env:AZURE_CLI_DISABLE_CONNECTION_VERIFICATION = "1"

$terraformArgs = @()
$localSecretTfvars = Join-Path $PSScriptRoot "terraform.tfvars"

if (Test-Path $localSecretTfvars) {
  $terraformArgs += @("-var-file", $localSecretTfvars)
}
$terraformInitArgs = @("init", "-reconfigure")

if (-not $BuildImagesDuringApply) {
    $terraformArgs += @("-var", "build_images_during_apply=false")
}

if ($env:GITHUB_ACTIONS -eq "true") {
    $terraformInitArgs += @(
        "-backend-config=use_oidc=true",
        "-backend-config=use_azuread_auth=true"
    )
}
else {
    $terraformInitArgs += "-backend-config=use_cli=true"
}

function Invoke-Terraform {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Args
    )

    & terraform @Args
    $commandSucceeded = $?
    $exitCode = $LASTEXITCODE
    if ($null -eq $exitCode) {
        if ($commandSucceeded) {
            return
        }

        $exitCode = "unknown"
    }

    if ($exitCode -ne 0 -and $exitCode -ne "unknown") {
        throw "terraform $($Args -join ' ') failed with exit code $exitCode"
    }

    if ($exitCode -eq "unknown") {
        throw "terraform $($Args -join ' ') failed before returning a process exit code"
    }
}

function Ensure-DevWorkspace {
    $workspaceList = (& terraform workspace list) | ForEach-Object { $_.Trim() }
    if ($LASTEXITCODE -ne 0) {
        throw "terraform workspace list failed with exit code $LASTEXITCODE"
    }

    $workspaceNames = $workspaceList | ForEach-Object { $_.TrimStart("*").Trim() }
    if ($workspaceNames -contains "dev") {
        Invoke-Terraform -Args @("workspace", "select", "dev")
        return
    }

    Invoke-Terraform -Args @("workspace", "new", "dev")
}

function Ensure-Kubeconfig {
    $resourceGroup = (& terraform output -raw resource_group_name).Trim()
    if ($LASTEXITCODE -ne 0) {
        throw "terraform output -raw resource_group_name failed with exit code $LASTEXITCODE"
    }

    $clusterName = (& terraform output -raw aks_cluster_name).Trim()
    if ($LASTEXITCODE -ne 0) {
        throw "terraform output -raw aks_cluster_name failed with exit code $LASTEXITCODE"
    }

    $kubeconfigPath = Join-Path $PSScriptRoot ".generated-kubeconfig"
    & az aks get-credentials --resource-group $resourceGroup --name $clusterName --admin --overwrite-existing --file $kubeconfigPath | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "az aks get-credentials failed with exit code $LASTEXITCODE"
    }
}

Push-Location $PSScriptRoot
try {
    Invoke-Terraform -Args $terraformInitArgs

    if ($Action -eq "init") {
        Ensure-DevWorkspace
        return
    }

    Ensure-DevWorkspace

    if ($Action -ne "workspace") {
        Ensure-Kubeconfig
    }

    switch ($Action) {
        "workspace" {
            return
        }
        "plan" {
            Invoke-Terraform -Args (@("plan") + $terraformArgs)
        }
        "apply" {
            $applyArgs = @("apply") + $terraformArgs
            if ($AutoApprove) {
                $applyArgs += "-auto-approve"
            }
            Invoke-Terraform -Args $applyArgs
        }
    }
}
finally {
    Pop-Location
}
