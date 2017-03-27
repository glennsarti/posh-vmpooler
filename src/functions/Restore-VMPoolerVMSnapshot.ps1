Function Restore-VMPoolerVMSnapshot {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [Alias('hostname','Name','VMName')]
    [String]$VM,

    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [String]$Snapshot
  )
  
  Begin {   
  }
  
  Process {
    $result = Invoke-VMPoolerAPI -route "vm/$VM/snapshot/$Snapshot" -Payload '' -TokenAuth -ErrorAction 'Stop'

    $result #."$VM".snapshot
  }
  
  End {
  }
  
}