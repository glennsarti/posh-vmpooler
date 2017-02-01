function Connect-VMPooler {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low',DefaultParameterSetName='URLNoCreds')]
  param (


#Get-VMPoolerSavedCredentialURL
    [Parameter(Mandatory=$true,ValueFromPipeline=$false,ParameterSetName='DefaultURLWithCredential')]
    [Parameter(Mandatory=$true,ValueFromPipeline=$false,ParameterSetName='DefaultURLNoCreds')]
    [switch]$DefaultURL = $false,

    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='URLWithCredential')]
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='URLNoCreds')]
    [string]$URL = '',

    [Parameter(Mandatory=$true,ValueFromPipeline=$false,ParameterSetName='URLWithCredential')]
    [Parameter(Mandatory=$true,ValueFromPipeline=$false,ParameterSetName='DefaultURLWithCredential')]
    [PSCredential]$Credential = [System.Management.Automation.PSCredential]::Empty,
    
    [Parameter(Mandatory=$false,ValueFromPipeline=$false,ParameterSetName='URLWithCredential')]
    [Parameter(Mandatory=$false,ValueFromPipeline=$false,ParameterSetName='DefaultURLWithCredential')]
    [switch]$SaveCredentials = $false
  )
  
  Begin {
    if ($DefaultURL) {
      $URL = [string](Get-VMPoolerSavedCredentialURL | Select-Object -First 1)
    }
  }
  
  Process {
    # Confirm the VM Pooler URI
    if ($URL.EndsWith('/')) { $URL = $URL.SubString(0,$URL.Length - 1)}
    try {
      Get-VMPoolerStatus -URL $URL | Out-Null
    }
    catch {
      Write-Error "Could not connect to VMPooler at $url"
      return $false
    }
    $Script:VMPoolerServiceURI = $URL

    # Process credentials
    switch -Wildcard ($PsCmdlet.ParameterSetName) {
      "*WithCredential" {
        if ($Credential -eq [System.Management.Automation.PSCredential]::Empty) {
          $Credential = Get-Credential -UserName ($Env:Username) -Message "Credential to access VM Pooler"
        }
        $Script:VMPoolCredential = $Credential
        
        if ($SaveCredentials) {
          # Get the TokenID
          $TokenID = ""
          Get-VMPoolerToken | Select -First 1 | % { $TokenID = $_.TokenID }
          if ($TokenID -eq "") {
            $newToken = New-VMPoolerToken
            $TokenID = $newToken.TokenID
          }
          if ($TokenID -eq '') {
            throw "Unable to create a VM Pooler token"
            return $false
          }    

          Save-VMPoolerCredentials -PoolerURL $Script:VMPoolerServiceURI.ToLower() -TokenID $TokenID -Username ($Script:VMPoolCredential).Username | Out-Null
        }
        
      } 
      "*NoCreds" {
        # Load from environment variables
        $TokenID = [string](Get-Item ENV:'VMPOOL_TOKEN' -ErrorAction SilentlyContinue).Value
        $TokenUsername = [string](Get-Item ENV:'LDAP_USERNAME' -ErrorAction SilentlyContinue).Value
        if ( ($TokenID -ne '') -and ($TokenUsername  -ne '') ) {
          $Script:VMPoolCredential = [System.Management.Automation.PSCredential]::Empty
          $Script:VMPoolToken = $TokenID
          $Script:VMPoolTokenUsername = $TokenUsername
          Write-Verbose "Loaded credential information from the environment"
          return $true
        }
        # Load from registry
        $loadedCreds = Get-VMPoolerSavedCredentials -PoolerURL $Script:VMPoolerServiceURI.ToLower()
        if ($loadedCreds -ne $null) {
          $Script:VMPoolCredential = [System.Management.Automation.PSCredential]::Empty
          $Script:VMPoolToken = $loadedCreds.tokenid
          $Script:VMPoolTokenUsername = $loadedCreds.username
          Write-Verbose "Loaded credential information from the registry"
          return $true
        }
        throw "Credentials missing for pooler $($Script:VMPoolerServiceURI)"
        return $false
      }
      default {
        throw "Unknown parameterset name.  This is bad."
        return $false
      }
    }
    
    if ($Credential -ne [System.Management.Automation.PSCredential]::Empty) {
      $Script:VMPoolCredential = $Credential
    }

    return $true
  }
  
  End {
  }

}