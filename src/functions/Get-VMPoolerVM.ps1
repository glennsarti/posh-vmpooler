Function Get-VMPoolerVM {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [Alias('hostname','Name')]
    [String]$VM
  )
  
  Begin {   
  }
  
  Process {
    $result = Invoke-VMPoolerAPI -route "vm/$VM"

    $dateFormat = 'yyyy-MM-dd HH:mm:ss zzz'

    Get-Member -InputObject $result -MemberType NoteProperty | % {
      $vmName = $_.Name
      $objToken = ($result."$vmName")
      
      Add-Member -InputObject $objToken -MemberType NoteProperty -Name 'VMName' -Value $vmName

      $ttl = [int]$objToken.lifetime
      $age = [int]$objToken.running
      
      $Started = (Get-Date).AddMinutes(-60*$age)
      $Expires = $Started.AddHours($ttl)

      Add-Member -InputObject $objToken -MemberType NoteProperty -Name "Started" -Value $Started.ToString($dateFormat)
      Add-Member -InputObject $objToken -MemberType NoteProperty -Name "Expires" -Value $Expires.ToString($dateFormat)

      # $AllVMList = @()
      # Get-Member -InputObject ($objToken.vms) -MemberType NoteProperty | % {
      #   $VMState = $_.Name
      #   
      #   $StateVMList = @()
      #   $objToken.vms."$VMState" | % {
      #     $VMName = $_.ToString()
      #     
      #     $AllVMList += $VMName
      #     $StateVMList += $VMName
      #   }
      #   Add-Member -InputObject $objToken -MemberType NoteProperty -Name "VMs_$($VMState)" -Value $StateVMList
      # }
      # Add-Member -InputObject $objToken -MemberType NoteProperty -Name "VMs_all" -Value $AllVMList
       
      Write-Output $objToken
    }
  }
  
  End {
  }
  
}