function Connect-VMPooler {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]$URL = ''

    ,[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
    [PSCredential]$Credential = [System.Management.Automation.PSCredential]::Empty
  )
  
  Begin {
  }
  
  Process {
    if ($URL.EndsWith('/')) { $URL = $URL.SubString(0,$URL.Length - 1)}
    try {
      Get-VMPoolerStatus -URL $URL | Out-Null
    }
    catch {
      Write-Error "Could not connect to VMPooler at $url"
      return
    }
    
    $Script:VMPoolerServiceURI = $URL
    
    if ($Credential -ne [System.Management.Automation.PSCredential]::Empty) {
      $Script:VMPoolCredential = $Credential
    }
  }
  
  End {
  }

}