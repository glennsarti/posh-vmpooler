function Get-VMPoolerConnection {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param ()
  
  Begin {
  }
  
  Process {
    $hash = @{
      'uri' = [string]$Script:VMPoolerServiceURI
      'username' = [string]$Script:VMPoolTokenUsername
    }

    return $hash
  }
  
  End {
  }
}