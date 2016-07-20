Function Remove-VMPoolerVM {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [Alias('hostname','Name','VM')]
    [String]$VMName
  )
  
  Begin {   
  }
  
  Process {
    Invoke-VMPoolerAPI -route "vm/$VMName" -Method 'DELETE' -TokenAuth -ErrorAction 'Stop' | Out-Null

    Get-VMPoolerVM -VM $VMName
  }
  
  End {
  }
  
}