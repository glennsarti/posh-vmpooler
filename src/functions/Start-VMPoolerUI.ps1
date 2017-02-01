function Start-VMPoolerUI {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param (
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]$URL = ''

    ,[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
    [PSCredential]$Credential = [System.Management.Automation.PSCredential]::Empty
  
    ,[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
    [switch]$SaveCredentials = $false
)

  Begin {
  }

  Process {
    # Load XAML from the external file
    Write-Verbose "Loading the window XAML..."
    [xml]$xaml = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath 'poolerui\PoolerUI.xaml'))

    # Build the GUI
    Write-Verbose "Parsing the window XAML..."
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $thisWindow = [Windows.Markup.XamlReader]::Load($reader)

    # Wire up the XAML
    Write-Verbose "Adding XAML event handlers..."

    (Get-WPFControl 'btnCreateVM' -Window $thisWindow).Add_Click({
      $currentConnection = Get-VMPoolerConnection
      if ($currentConnection.uri -eq '') { return }

      [string]$PoolName = (Get-WPFControl 'cboTemplates' -Window $thisWindow).SelectedValue

      if ($Poolname -ne '') {
        try {
          New-VMPoolerVM -Pool $PoolName
          (Get-WPFControl 'xmlPoolerDetail' -Window $thisWindow).Document = (Get-VMPoolerAllVMsAsXML)
        } catch {
          Write-Warning "Unable to create a VM in pool $PoolName"
        }
      }
    })

    (Get-WPFControl 'butRefresh' -Window $thisWindow).Add_Click({
      $currentConnection = Get-VMPoolerConnection
      if ($currentConnection.uri -eq '') { return }

      (Get-WPFControl 'xmlPoolerDetail' -Window $thisWindow).Document = (Get-VMPoolerAllVMsAsXML)
    })

    (Get-WPFControl 'btnConnectPooler' -Window $thisWindow).Add_Click({
      $currentConnection = Get-VMPoolerConnection
      if ($currentConnection.uri -ne '') { return }
      $vp = ($VerbosePreference -eq 'Continue')

      $PoolerURI = (Get-WPFControl 'cboPoolerURL' -Window $thisWindow).Text
      $saveCreds = ((Get-WPFControl 'chkSaveCreds' -Window $thisWindow).IsChecked -eq $true)

      $result = $false
      $connErr = $null
      try {
        $result = Connect-VMPooler -URL $PoolerURI -ErrorAction Stop -Verbose:$vp
      } catch {
        $connErr = $_.Exception
      }

      if (-not $result) {
        if ($connErr -eq $null) { throw "Could not connect to $PoolerURI"; return }
        if ($connErr.Message -notlike '*Credentials Missing*') { Throw $conErr; return }

        $result = Connect-VMPooler -URL $PoolerURI -SaveCredentials:$saveCreds -Credential (Get-Credential -Message "Connect to $PoolerURI" -ErrorAction Stop) -ErrorAction Stop -Verbose:$vp
      }

      if (-not $result) { Throw "Unable to connect"; return }
   
      (Get-WPFControl 'cboPoolerURL' -Window $thisWindow).IsEnabled = $false
      (Get-WPFControl 'btnConnectPooler' -Window $thisWindow).IsEnabled = $false
      (Get-WPFControl 'chkSaveCreds' -Window $thisWindow).IsEnabled = $false
      (Get-WPFControl 'butRefresh' -Window $thisWindow).IsEnabled = $true
      (Get-WPFControl 'cboTemplates' -Window $thisWindow).IsEnabled = $true
      (Get-WPFControl 'btnCreateVM' -Window $thisWindow).IsEnabled = $true

      Write-Verbose "Getting pool list..."
      (Get-WPFControl 'xmlPoolList' -Window $thisWindow).Document = (Get-VMPoolerPoolAsXML -Verbose:$vp)
      Write-Verbose "Getting pooler VMs list..."
      (Get-WPFControl 'xmlPoolerDetail' -Window $thisWindow).Document = (Get-VMPoolerAllVMsAsXML -Verbose:$vp)
    })

    # Generic handler for all Buttons in the VMList ItemsControl
    $objVMList = (Get-WPFControl 'VMList' -Window $thisWindow)
    $objVMList | Add-EventHandler -EventName "Click" -SourceType 'System.Windows.Controls.Button' -Handler {
      $ButtonTag = ''
      try {
        # Assumes an XML Attribute type that is databound
        $ButtonTag = $e.OriginalSource.Tag.Value.ToString()
      } catch { $ButtonTag = '' }
      if ($ButtonTag -eq '') { return }

      # Take action depending on the Button x:Name property
      switch ($e.OriginalSource.Name) {
        "butDeleteVM" {
          Remove-VMPoolerVM -VMName $ButtonTag | Out-Null
          Start-Sleep -Milliseconds 100 # Just a small sleep to let pooler catchup...
          (Get-WPFControl 'xmlPoolerDetail' -Window $thisWindow).Document = (Get-VMPoolerAllVMsAsXML)
        }
        "butConnectRDP" {
          $vm = Get-VMPoolerVM -VM $ButtonTag
          Start-Process -FilePath "mstsc.exe" -ArgumentList @("/v:$($vm.FQDN)") -Wait:$false -NoNewWindow:$false | Out-Null
        }
        "butConnectPS" {
          $vm = Get-VMPoolerVM -VM $ButtonTag
          Start-Process -FilePath "powershell.exe" `
            -ArgumentList @('-NoExit',"`"& { Enter-PSSession -Computername '$($vm.FQDN)' -Credential '$($vm.FQDN)\Administrator' -UseSSL -SessionOption (New-PSSessionOption -SkipCACheck) }`"") `
            -Wait:$false -NoNewWindow:$false | Out-Null
        }
        "butAddTime" {
          $vm = Get-VMPoolerVM -VM $ButtonTag

          $lifetime = $vm.lifetime + 2

          $vm | Set-VMPoolerVMOptions -LifeTime $lifetime | Out-Null

          (Get-WPFControl 'xmlPoolerDetail' -Window $thisWindow).Document = (Get-VMPoolerAllVMsAsXML)
        }
        "butConnectSSH" {
          $vm = Get-VMPoolerVM -VM $ButtonTag

          $sshEXE = ''
          # Find putty in search
          if ($sshEXE -eq '') {
            $puttyExe = (Get-Command 'putty.exe' -ErrorAction SilentlyContinue)
            if ($puttyExe -ne $null) { $sshEXE = $puttyExe.Path }
          }
          # Find ssh in search
          if ($sshEXE -eq '') {
            $sshclientExe = (Get-Command 'ssh.exe' -ErrorAction SilentlyContinue)
            if ($sshclientExe -ne $null) { $sshEXE = $sshclientExe.Path }
          }
          # Find in Git directory
          $gitssh = 'C:\Program Files\Git\usr\bin\ssh.exe'
          if ( (Test-Path -Path $gitssh) -and ($sshEXE -eq '') ) { $sshEXE = $gitssh}

          if ($sshEXE -eq '') { Write-Warning "Could not find an SSH Client"; return; }

          Start-Process -FilePath $sshEXE `
            -ArgumentList @("$($vm.FQDN)") `
            -Wait:$false -NoNewWindow:$false | Out-Null
        }
        default {  Write-Host "Unhandled click on button $($e.OriginalSource.Name)" }
      }
    }

    # Init the disabled UI
    (Get-WPFControl 'cboPoolerURL' -Window $thisWindow).IsEnabled = $false
    (Get-WPFControl 'btnConnectPooler' -Window $thisWindow).IsEnabled = $false
    (Get-WPFControl 'chkSaveCreds' -Window $thisWindow).IsEnabled = $false
    (Get-WPFControl 'butRefresh' -Window $thisWindow).IsEnabled = $false
    (Get-WPFControl 'cboTemplates' -Window $thisWindow).IsEnabled = $false
    (Get-WPFControl 'btnCreateVM' -Window $thisWindow).IsEnabled = $false

    # TODO Add current saved URLs into combobox
    (Get-WPFControl 'cboPoolerURL' -Window $thisWindow).Items.Clear()
    Get-VMPoolerSavedCredentialURL | % {
      (Get-WPFControl 'cboPoolerURL' -Window $thisWindow).Items.Add($_) | Out-Null
    }
    if ((Get-WPFControl 'cboPoolerURL' -Window $thisWindow).Items.Count -eq 0) {
      (Get-WPFControl 'cboPoolerURL' -Window $thisWindow).Items.Add('https://vmpooler.delivery.puppetlabs.net/api/v1') | Out-Null
    }
    (Get-WPFControl 'cboPoolerURL' -Window $thisWindow).SelectedIndex = 0

    if ($URL -ne '') {
      if ($Credential -ne [System.Management.Automation.PSCredential]::Empty) {
        Connect-VMPooler -URL $URL -Credential $Credential -SaveCredentials:$SaveCredentials | Out-Null
      } else {
        Connect-VMPooler -URL $URL | Out-Null
      }
      # Write the xml document to the XAML for databinding
      (Get-WPFControl 'xmlPoolList' -Window $thisWindow).Document = (Get-VMPoolerPoolAsXML)
      (Get-WPFControl 'xmlPoolerDetail' -Window $thisWindow).Document = (Get-VMPoolerAllVMsAsXML)

      (Get-WPFControl 'butRefresh' -Window $thisWindow).IsEnabled = $true
      (Get-WPFControl 'cboTemplates' -Window $thisWindow).IsEnabled = $true
      (Get-WPFControl 'btnCreateVM' -Window $thisWindow).IsEnabled = $true
    } else {
      (Get-WPFControl 'cboPoolerURL' -Window $thisWindow).IsEnabled = $true
      (Get-WPFControl 'btnConnectPooler' -Window $thisWindow).IsEnabled = $true      
      (Get-WPFControl 'chkSaveCreds' -Window $thisWindow).IsEnabled = $true
    }

    # Show the GUI
    Write-Verbose "Showing the window..."
    [void]($thisWindow.ShowDialog())
    Write-Verbose "Cleanup..."
    $thisWindow.Close()
    $thisWindow = $null
  }

  End {
  }

}