$Script:VMPoolCredential = [System.Management.Automation.PSCredential]::Empty
$Script:VMPoolToken = [string](Get-Item ENV:'VMPOOL_TOKEN' -ErrorAction SilentlyContinue).Value
$Script:VMPoolerServiceURI = [string](Get-Item ENV:'VMPOOL_URL' -ErrorAction SilentlyContinue).Value

Invoke-Command -ScriptBlock {
  $username = [string](Get-Item ENV:'LDAP_USERNAME' -ErrorAction SilentlyContinue).Value
  $password = [string](Get-Item ENV:'LDAP_PASSWORD' -ErrorAction SilentlyContinue).Value
  
  if ( ($username -ne '' ) -and ($password -ne '') ) {
    $secpwd = ConvertTo-SecureString -AsPlainText -Force -String $password
    $Script:VMPoolCredential = New-Object -Type System.Management.Automation.PSCredential($username,$secpwd)
  }
} | Out-Null

#Load Required Assemblies
Write-Verbose 'Loading WPF assemblies'
Add-Type -assemblyName PresentationFramework
Add-Type -assemblyName PresentationCore
Add-Type -assemblyName WindowsBase
Write-Verbose 'Loading Windows Forms assemblies'
Add-Type -AssemblyName System.Windows.Forms    
