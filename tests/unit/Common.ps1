$DebugPreference = "SilentlyContinue"

$here = Split-Path -Parent $MyInvocation.MyCommand.Definition
$src = Resolve-Path -Path "$($here)\..\..\src\functions"

$global:MockVMName = 'vmname'
$global:MockVMHash = @{
  'VMName' = $global:MockVMName
}
