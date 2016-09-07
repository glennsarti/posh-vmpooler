function Get-VMPoolerSavedCredentialURL {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param ()
  
  Begin {   
  }
  
  Process {
    $regKey = 'Registry::HKEY_CURRENT_USER\Software\PoshVMPooler\VMPooler'

    Get-ItemProperty -Path $regKey | Get-Member -MemberType NoteProperty | ? { $_.Name -notlike 'PS*'} | % {
      Write-Output ($_.Name)
    }
  }
  
  End {
  }
}
