function Get-VMPoolerSavedCredentials {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [string]$PoolerURL    
  )
  
  Begin {   
  }
  
  Process {
    $key = $PoolerURL
    
    $encString = ''
    $regKey = 'Registry::HKEY_CURRENT_USER\Software\PoshVMPooler\VMPooler'
    try {
      $objRegValue = Get-ItemProperty -Path $regkey -Name $key
      $encString = $objRegValue."$($key)"
    }
    catch [System.Exception] {
      # Any error assume the key does not exist
      $encString = ''
    }
    if ($encString -eq '') { return $null}

    # Decrypt
    $secureString = (ConvertTo-SecureString -String $encString)
    
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
    $unencString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    $unencArr = $unencString.split("`t")
    return (@{
      'username' = $unencArr[0]
      'tokenid' = $unencArr[1]
    })
  }
  
  End {
  }
}
