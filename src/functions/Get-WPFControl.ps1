function Get-WPFControl {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]$ControlName

    ,[Parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [System.Windows.Window]$Window
  )  
  Process {
    Write-Output $Window.FindName($ControlName)
  }
}