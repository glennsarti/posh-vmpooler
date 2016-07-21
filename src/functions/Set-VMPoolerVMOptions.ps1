Function Set-VMPoolerVMOptions {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [Alias('hostname','Name','VM')]
    [String]$VMName

    ,[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
    [HashTable]$Tags = @{}

    ,[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
    [ValidateRange(1,72)]
    [Alias('TTL','LifeTime')]
    [int]$TimeToLive = 0
  )
  
  Begin {   
  }
  
  Process {
    $body = @{}
    if ($Tags.Count -gt 0) { $body.tags = $Tags }
    if ($TimeToLive -gt 0) { $body.lifetime = $TimeToLive}

    if ($body.Count -gt 0) {
      Invoke-VMPoolerAPI -route "vm/$VMName" -Payload $body -Method 'PUT' -TokenAuth -ErrorAction 'Stop' | Out-Null
    }

    Get-VMPoolerVM -VM $VMName
  }
  
  End {
  }
  
}