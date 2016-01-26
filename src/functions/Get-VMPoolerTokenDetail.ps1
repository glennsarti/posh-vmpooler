Function Get-VMPoolerTokenDetail {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [String]$TokenID
  )
  
  Begin {   
  }
  
  Process {
    $result = Invoke-VMPoolerAPI -route "token/$TokenID"
$result | Out-GridView -Wait
    # Get-Member -InputObject $result -MemberType NoteProperty | % {
    #   $tokenName = $_.Name
    #   Get-Member -InputObject ($result."$tokenName") -MemberType NoteProperty | % {
    #     $propertyHash."$($_.Name)" = $result."$tokenName"."$($_.Name)" 
    #   }
    #         
    #   Write-Output (New-Object -TypeName PSObject -Property $propertyHash)
    # }
    
    Write-Output $result
  }
  
  End {
  }
  
}