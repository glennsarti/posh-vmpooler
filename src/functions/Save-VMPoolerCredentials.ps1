function Save-VMPoolerCredentials {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [string]$Username
    
    ,[Parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [string]$TokenID
    
    ,[Parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [string]$PoolerURL
    
  )
  
  Begin {   
  }
  
  Process {
    Write-Warning "*** Saving your credentials is not totally secure.  Only your username and first token are encrypted and saved"

    $key = $PoolerURL
    
    $plaintext = "$($Username)`t$($TokenID)"
    $secureString = (ConvertTo-SecureString -String $plainText -AsPlainText -Force)
    $encString = (ConvertFrom-SecureString -SecureString $secureString)
    
    # Save encrypted text to reg
    $regKey = 'Registry::HKEY_CURRENT_USER\Software\PoshVMPooler\VMPooler'
    if (-not (Test-Path -Path $regKey)) {
      New-Item -Path $regKey -ItemType Directory -Force | Out-Null
    }
    # Create the reg value
    New-ItemProperty -Path $regKey -Name $Key -Value $encString -PropertyType String -Force | Out-Null
    
    return $true    
  }
  
  End {
  }
}
