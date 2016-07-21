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
    $newHostname = $result."$Pool".hostname #" 
    if ([string]::IsNullOrEmpty($newHostname)) {
      throw "Unable to create a VM in pool $Pool"
    }

    try {
      Set-VMPoolerVMOptions -VM $newHostname -Tags (@{"client" = "$($Script:VMPoolerClientTag)"; "username" = "$($Script:VMPoolTokenUsername)"; })
    } catch {
      Write-Warning "Unable to set tags on new vm"
    }
  }
  
  End {
  }
  
}