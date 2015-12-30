function Connect-VMPooler {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]$URL = ''
  )
  
  Begin {
  }
  
  Process {
    if ($URL.EndsWith('/')) { $URL = $URL.SubString(0,$URL.Length - 1)}
    try {
      $result = Get-VMPoolerStatus -URL $URL
    }
    catch {
      Write-Error "Could not connect to VMPooler at $url"
      return
    }
    
    $Script:VMPoolerServiceURI = $URL
  }
  
  End {
  }

}