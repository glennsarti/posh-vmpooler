Function Get-VMPoolerVM {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [Alias('hostname','Name','VMName')]
    [String]$VM
  )
  
  Begin {   
  }
  
  Process {
    $result = Invoke-VMPoolerAPI -route "vm/$VM" -NoAuth

    $dateFormat = 'yyyy-MM-dd HH:mm:ss zzz'

    Get-Member -InputObject $result -MemberType NoteProperty | % {
      $vmName = $_.Name
      $objToken = ($result."$vmName")
      
      Add-Member -InputObject $objToken -MemberType NoteProperty -Name 'VMName' -Value $vmName
      Add-Member -InputObject $objToken -MemberType NoteProperty -Name 'FQDN' -Value "$($vmName).$($objToken.domain)"

      $ttl = [int]$objToken.lifetime
      $age = [double]$objToken.running
      
      $Started = (Get-Date).AddMinutes(-60*$age)
      $Expires = $Started.AddHours($ttl)
      $MinutesLeft = (New-Timespan -End $Expires).TotalMinutes

      Add-Member -InputObject $objToken -MemberType NoteProperty -Name "Started" -Value $Started.ToString($dateFormat)
      Add-Member -InputObject $objToken -MemberType NoteProperty -Name "Expires" -Value $Expires.ToString($dateFormat)
      Add-Member -InputObject $objToken -MemberType NoteProperty -Name "MinutesLeft" -Value $MinutesLeft.ToString("0")

      if (-not ($objToken.PSobject.Properties.Name -contains "snapshots")) {
        Add-Member -InputObject $objToken -MemberType NoteProperty -Name "snapshots" -Value @()
      }
      if (-not ($objToken.PSobject.Properties.Name -contains "disk")) {
        Add-Member -InputObject $objToken -MemberType NoteProperty -Name "disk" -Value @()
      }

      Write-Output $objToken
    }
  }
  
  End {
  }
  
}