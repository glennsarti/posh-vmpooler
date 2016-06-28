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

    Get-Member -InputObject $result -MemberType NoteProperty | % {
      $tokenName = $_.Name
      $objToken = ($result."$tokenName")
      
      Add-Member -InputObject $objToken -MemberType NoteProperty -Name 'TokenID' -Value $tokenName

      $AllVMList = @()
      if ($objToken.vms -ne $null) {        
        Get-Member -InputObject ($objToken.vms) -MemberType NoteProperty | % {
          $VMState = $_.Name
          
          $StateVMList = @()
          $objToken.vms."$VMState" | % {
            $VMName = $_.ToString()
            
            $AllVMList += $VMName
            $StateVMList += $VMName
          }
        }
        Add-Member -InputObject $objToken -MemberType NoteProperty -Name "VMs_$($VMState)" -Value $StateVMList
      }
      Add-Member -InputObject $objToken -MemberType NoteProperty -Name "VMs_all" -Value $AllVMList
       
      Write-Output $objToken
    }
  }
  
  End {
  }
  
}