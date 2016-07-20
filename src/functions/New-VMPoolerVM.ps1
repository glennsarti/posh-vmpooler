Function New-VMPoolerVM {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='SingleVM')]
    [Alias('poolname')]
    [String]$Pool
  )
  
  Begin {   
  }
  
  Process {
    $result = Invoke-VMPoolerAPI -route "vm/$Pool" -Payload '' -TokenAuth  -ErrorAction 'Stop'
    $newHostname = $result."$Pool".hostname
    if ([string]::IsNullOrEmpty($newHostname)) {
      throw "Unable to create a VM in pool $Pool"
    }

    Set-VMPoolerVMTags -VM $newHostname -Tags (@{"client" = "$($Script:VMPoolerClientTag)"; "username" = "$($Script:VMPoolTokenUsername)"; })
  }
  
  End {
  }
  
}