Function Get-VMPoolerToken {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param (
    #[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    #[String]$Filter = ".*"
  )
  
  Begin {   
  }
  
  Process {
    if (($Script:VMPoolCredential -eq [System.Management.Automation.PSCredential]::Empty) -and ($Script:VMPoolToken -ne '')) {
      # Cached TokenID
      $propertyHash = @{ 'TokenID' = $Script:VMPoolToken }
      return (New-Object -TypeName PSObject -Property $propertyHash)      
    }

    try {
      $result = Invoke-VMPoolerAPI -route 'token'

      Get-Member -InputObject $result -MemberType NoteProperty | % {
        
        $tokenName = $_.Name
        $objToken = $result."$tokenName"
        $propertyHash = @{ 'TokenID' = $tokenName }
        
        $objToken | Get-Member -MemberType NoteProperty | % {
          $propertyHash."$($_.Name)" = $objToken."$($_.Name)" 
        }
              
        Write-Output (New-Object -TypeName PSObject -Property $propertyHash)
      }
    }
    catch {
      # Errors here indicate either the use has no tokens assigned
      # or bad username password
    }
  }
  
  End {
  }
  
}