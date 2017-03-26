Function New-VMPoolerVMSnapshot {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [Alias('hostname','Name','VMName')]
    [String]$VM
  )
  
  Begin {   
  }
  
  Process {
    $result = Invoke-VMPoolerAPI -route "vm/$VM/snapshot" -Payload '' -TokenAuth -ErrorAction 'Stop'

    $result."$VM".snapshot
  }
  
  End {
  }
  
}