function Get-VMPoolerPool {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param (
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [String]$Filter = ".*"
  )
  
  Begin {   
  }
  
  Process {
    (Invoke-VMPoolerAPI -route 'vm' -NoAuth -NoParseResponse).GetEnumerator() | ? { $_ -match $Filter } |  % { Write-Output ([string]$_) }
  }
  
  End {
  }
}