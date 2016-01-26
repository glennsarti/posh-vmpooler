Function Get-VMPoolerToken {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param (
    #[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    #[String]$Filter = ".*"
  )
  
  Begin {   
  }
  
  Process {
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
  
  End {
  }
  
}