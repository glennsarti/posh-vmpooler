function Get-VMPoolerStatus {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param (
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]$URL = ''
  )
  
  Begin {
  }
  
  Process {
    if ($URL -eq '') { $URL = $VMPoolerServiceURI }
    if ($URL -eq '') { Write-Error "Missing VMPooler URL"; return }
    
    Invoke-VMPoolerAPI -url $URL -route 'status' -NoAuth -NoParseResponse
  }
  
  End {
  }
}