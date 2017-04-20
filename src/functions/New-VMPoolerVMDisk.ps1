Function New-VMPoolerVMDisk {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [Alias('hostname','Name','VMName')]
    [String]$VM

    ,[Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [Alias('disk','size')]
    [Int]$DiskSize
  )
  
  Begin {   
  }
  
  Process {
    $result = Invoke-VMPoolerAPI -route "vm/$VM/disk/$DiskSize" -Payload '' -TokenAuth -ErrorAction 'Stop'

    $result."$VM".disk
  }
  
  End {
  }
  
}