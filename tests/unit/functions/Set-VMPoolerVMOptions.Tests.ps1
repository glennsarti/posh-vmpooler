$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
$common = Join-Path (Split-Path -Parent $here) 'Common.ps1'
. $common

Import-Module "$src\VMPooler.psm1"

InModuleScope VMPooler {
  Describe 'Set-VMPoolerVMOptions' {

    Mock Invoke-VMPoolerAPI { Throw "Should not call Invoke-VMPoolerAPI"}
    Mock Get-VMPoolerVM { Throw "Should not call Get-VMPoolerVM"}

    Mock Get-VMPoolerVM -ParameterFilter { $VMName -eq $MockVMName } -MockWith { $global:MockVMHash }


    Context 'When Tags or TTL are not specified' {
      It "should not call VMPooler" {
        Set-VMPoolerVMOptions -VMName $global:MockVMName | Out-Null

        Assert-MockCalled Invoke-VMPoolerAPI -Times 0
      }

      It "should return a VM hash" {
        Set-VMPoolerVMOptions -VMName $global:MockVMName | Should be $global:MockVMHash
      }
    }

 
    Context 'When setting Tags Property' {
      # It "should have empty payload by default" {
      #   Mock Invoke-VMPoolerAPI { $false } -ParameterFilter { 
      #     $Payload -eq @{}
      #   }       
      #   Mock Get-VMPoolerVM { 'VM' }

      #   Set-VMPoolerVMOptions -VMName 'vmname' | Should be 'VM'
      # }

      # It "should add tags to payload" {
      #   Mock Invoke-VMPoolerAPI { $false } -ParameterFilter { 
      #     $Payload -eq @{}
      #   }       
      #   Mock Get-VMPoolerVM { 'VM' }

      #   Set-VMPoolerVMOptions -VMName 'vmname' -Tags @{ 'tag1' = 'value1' } | Should be 'VM'
      # }
      
    }

    # Context 'VMName property' {

    #   It "should accept the alias of hostname" {
    #     Mock Invoke-VMPoolerAPI { $false }        
    #     Mock Get-VMPoolerVM { 'VM' }

    #     Set-VMPoolerVMOptions -hostname 'vmname' | Should be 'VM'
    #   }

    #   It "should accept the alias of Name" {
    #     Mock Invoke-VMPoolerAPI { $false }        
    #     Mock Get-VMPoolerVM { 'VM' }

    #     Set-VMPoolerVMOptions -Name 'vmname' | Should be 'VM'
    #   }
# Pipes?
    #   It "should accept the alias of VM" {
    #     Mock Invoke-VMPoolerAPI { $false }        
    #     Mock Get-VMPoolerVM { 'VM' }

    #     Set-VMPoolerVMOptions -VM 'vmname' | Should be 'VM'
    #   }
    # }

    Context 'When setting TimeToLive Property' {
      $lifetime = 4

      Mock Invoke-VMPoolerAPI

      It "should return a VM hash" {
        Set-VMPoolerVMOptions -TimeToLive $lifetime -VMName $global:MockVMName | Should be $global:MockVMHash
      }

      It "should use the vm/xxxx route" {
        Mock Invoke-VMPoolerAPI -Verifiable -ParameterFilter { 
          $route -eq "vm/$($global:MockVMName)"
        }       

        Set-VMPoolerVMOptions -TimeToLive $lifetime -VMName $global:MockVMName | Out-Null

        Assert-VerifiableMocks
      }

      It "should use the PUT method" {
        Mock Invoke-VMPoolerAPI -Verifiable -ParameterFilter { 
          $Method -eq "PUT"
        }       

        Set-VMPoolerVMOptions -TimeToLive $lifetime -VMName $global:MockVMName | Out-Null

        Assert-VerifiableMocks
      }

      It "should use token authentication" {
        Mock Invoke-VMPoolerAPI -Verifiable -ParameterFilter {$TokenAuth -eq $true}

        Set-VMPoolerVMOptions -TimeToLive $lifetime -VMName $global:MockVMName | Out-Null

        Assert-VerifiableMocks
      }

      It "should set the lifetime in the request" {
        Mock Invoke-VMPoolerAPI -Verifiable -ParameterFilter {$body.lifetime -eq $lifetime}

        Set-VMPoolerVMOptions -TimeToLive $lifetime -VMName $global:MockVMName | Out-Null

        Assert-VerifiableMocks
      }

      It "should accept the alias of TTL" {
        Set-VMPoolerVMOptions -TTL $lifetime -VMName $global:MockVMName | Should be $global:MockVMHash
      }

      It "should accept the alias of LifeTime" {
        Set-VMPoolerVMOptions -LifeTime $lifetime -VMName $global:MockVMName | Should be $global:MockVMHash
      }

      0,73,-1 | ForEach-Object {
        $testCase = $_
        It "should not accept a number of $testCase" {
          { Set-VMPoolerVMOptions -TimeToLive $testCase -VMName $global:MockVMName } | Should Throw
        }
      }

      1,72,24,48 | ForEach-Object {
        $testCase = $_
        It "should accept a number of $testCase" {
          Set-VMPoolerVMOptions -TimeToLive $testCase -VMName $global:MockVMName | Out-Null
        }
      }
    }
  }
}