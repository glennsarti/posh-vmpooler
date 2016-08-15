function Add-EventHandler {
    <#
    .Synopsis
        Adds an event handler to an object
    .Description
        Adds an event handler to an object.  If the object has a
        resource dictionary, it will add an eventhandlers
        hashtable to that object and it will store the event handler,
        so it can be removed later.
    .Example
        $window = New-Window
        $window | Add-EventHandler Loaded { $this.Top = 100 }
    .Parameter Object
        The Object to add an event handler to
    .Parameter EventName
        The name of the event (i.e. Loaded)
    .Parameter Handler
        The script block that will handle the event
    .Parameter SourceType
        For RoutedEvents, the type that originates the event
    .Parameter PassThru
        If this is set, the delegate that is added to the object will
        be returned from the function.
    #>
    param(
    [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position = 0, ParameterSetName="SimpleEvents")]
    [ValidateNotNull()]
    [Alias("Object")]
    $InputObject,

    [Parameter(Mandatory=$true, Position=1)]
    [String]
    $EventName,

    [Parameter(Mandatory=$true, Position=2)]
    [ScriptBlock]
    $Handler,

    [Parameter(Mandatory=$false)]
    [String]
    $SourceType,

    [Switch]
    $PassThru
    )

    process {
        if($SourceType) {
            $Type = $SourceType -as [Type]
            if(!$Type) {
                $Type = (Get-Command $SourceType).OutputType[0].Type
            }
            if(!$Type) {
                Write-Error "Can't determine type from '$SourceType', you should pass either a Type or the name of a ShowUI command that outputs a UI Element. We will try the InputObject(s)"
                $Type = $InputObject.GetType()
            }
        } else {
            $Type = $InputObject.GetType()
        }

        if ($eventName.StartsWith("On_")) {
            $eventName = $eventName.Substring(3)
        }

        $Event = $Type.GetEvent($EventName, [Reflection.BindingFlags]"IgnoreCase, Public, Instance")
        if (-not $Event) {
            Write-Error "Handler $EventName does not exist on $InputObject"
            return
        }

        $realHandler = ([ScriptBlock]::Create(@"
  `$sender = `$args[0]
  `$e      = `$args[1]

  $Handler
"@)) -as $event.EventHandlerType

#         $realHandler = ([ScriptBlock]::Create(@"
# `$eventName = 'On_$eventName';
# . Initialize-EventHandler
# `$ErrorActionPreference = 'stop'

# $Handler

# trap {
#     . Write-WPFError `$_
#     continue
# }
# "@)) -as $event.EventHandlerType

        if($realHandler -is [System.Windows.RoutedEventHandler] -and $Type::"${EventName}Event" ) {
            $InputObject.AddHandler( $Type::"${EventName}Event", $realHandler )
        } else {

            if ($InputObject.Resources) {

                if (-not $InputObject.Resources.EventHandlers) {
                    $InputObject.Resources.EventHandlers = @{}
                }
                $InputObject.Resources.EventHandlers."On_$EventName" = $realHandler #"
            }
            $event.AddEventHandler($InputObject, $realHandler)
        }
        if ($passThru) {
            $RealHandler
        }
    }
}


Function Get-VMPoolerAllVMsAsXML {
  [xml]$xmlDoc = '<poolerdetail xmlns=""></poolerdetail>'
  Get-VMPoolerToken | Get-VMPoolerTokenDetail | % {
    # Convert the tokens
    $xmlToken = $xmlDoc.CreateElement('token')
    $xmlToken.SetAttribute('name',$_.TokenID)
    $xmlToken.SetAttribute('created',$_.created)
    $xmlToken.SetAttribute('lastuse',$_.last)
    $xmlDoc.poolerdetail.AppendChild($xmlToken) | Out-Null

    # Convert all the VMs
    $_.VMs_all | % { Get-VMPoolerVM -VM $_ } | % {
      $xmlVM = $xmlDoc.CreateElement('vm')
      $xmlVM.SetAttribute('name',$_.VMName)
      $xmlVM.SetAttribute('domain',$_.domain)
      $xmlVM.SetAttribute('template',$_.template)
      $xmlVM.SetAttribute('lifetime',$_.lifetime)
      $xmlVM.SetAttribute('running',$_.running)
      $xmlVM.SetAttribute('state',$_.state)
      if ($_.ip -eq '') {
        $xmlVM.SetAttribute('ip','MISSING!')
      } else {
        $xmlVM.SetAttribute('ip',$_.ip)
      }

      if ($_.tags -ne $null) {
        # Append tag elements
        $tags = $_.tags
        Get-Member -InputObject $_.tags -MemberType NoteProperty | % {
          $tagName = $_.Name
          $xmlNode = $xmlDoc.CreateElement('tag')
          $xmlNode.SetAttribute('key',$tagName)
          $xmlNode.SetAttribute('value',$tags."$tagName") #"
          $xmlVM.AppendChild($xmlNode) | Out-Null
        }
      }

      # Create pretty version of minutes left
      $PrettyMins = ''
      if ($_.MinutesLeft -le 0) {
        $PrettyMins = 'Now'
      } else {
        $ts = New-TimeSpan -Minutes $_.MinutesLeft
        if ($ts.Days -gt 0) {
          $PrettyMins = $PrettyMins + "$($ts.Days)d "
        }
        if ($ts.Hours -gt 0) {
          $PrettyMins = $PrettyMins + "$($ts.Hours)h "
        }
        if ($ts.Minutes -gt 0) {
          $PrettyMins = $PrettyMins + "$($ts.Minutes)m"
        }
      }

      $xmlVM.SetAttribute('FQDN',$_.FQDN)
      $xmlVM.SetAttribute('Started',$_.Started)
      $xmlVM.SetAttribute('Expires',$_.Expires)
      $xmlVM.SetAttribute('MinutesLeft',$_.MinutesLeft)
      $xmlVM.SetAttribute('PrettyMinutesLeft',$PrettyMins)
      $poolIcon = Get-VMPoolerPoolIcon -Poolname ($_.template)
      $xmlVM.SetAttribute('TemplateIcon',$poolIcon)

      $xmlToken.AppendChild($xmlVM) | Out-Null
    }
  }
  Write-Output $xmlDoc
}


function Get-VMPoolerPoolIcon($PoolName)
{
  # Last match wins
  $osIcon = ''
  @(
    '^debian-;http://icons.iconarchive.com/icons/tatice/operating-systems/16/Debian-icon.png',
    '^centos-;https://www.centos.org/favicon.ico',
    '^cisco-;http://natisbad.org/RH0/img/cisco-icon.png',
    '^ubuntu-;http://icons.iconarchive.com/icons/martz90/circle/16/ubuntu-icon.png',
    '^redhat-;http://www.megaicons.net/static/img/icons_sizes/291/735/16/apps-redhat-icon.png',
    '^fedora-;https://getfedora.org/static/images/fedora_infinity_140x140.png',
    '^oracle-;http://www.idevelopment.info/images/mini_oracle_html_logo.gif',
    '^opensuse-;https://www.opensuse.org/assets/images/favicon.png',
    '^osx-;http://vignette4.wikia.nocookie.net/wowwiki/images/a/a2/Apple-icon-16x16.png/revision/latest?cb=20080327031709',
    '^solaris-;https://www.iconattitude.com/icons/open_icon_library/apps/png/16/distributions-solaris.png',
    '^sles-;http://blog.seader.us/favicon.ico',
    '^scientific-;http://ftp.lip6.fr/pub/linux/distributions/scientific/graphics/version-3/icons/icon.png',
    '^win;http://icons.iconarchive.com/icons/dakirby309/simply-styled/16/OS-Windows-icon.png',
    '^win-20;http://www.easyhost.com/site/media/hw/icon-windows-small2.png',
    '^win-10;http://www.tobiidynavox.com/wp-content/uploads/2015/10/Icon_windows8_16x16.png'
  ) | % {
    $os = $_.Split(';')
    if ($PoolName -match $os[0]) { $osIcon = $os[1] }
  }

  Write-Output $osIcon
}

function Get-VMPoolerPoolAsXML {
  [xml]$xmlDoc = '<pools xmlns=""></pools>'

  Get-VMPoolerPool | % {
    $poolName = $_.ToString()
    $xmlNode = $xmlDoc.CreateElement('pool')
    $xmlNode.innerText = $poolName

    # Get OS Icon
    $osIcon =  Get-VMPoolerPoolIcon -poolname $poolName
    if ($osIcon -ne '') { $xmlNode.SetAttribute('osicon',$osIcon) }

    $xmlDoc.pools.AppendChild($xmlNode) | Out-Null
  }
  Write-Output $xmlDoc
}

function Start-VMPoolerUI {
  [cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]$URL = ''

    ,[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
    [PSCredential]$Credential = [System.Management.Automation.PSCredential]::Empty
  )

  Begin {
  }

  Process {
    # if ($URL.EndsWith('/')) { $URL = $URL.SubString(0,$URL.Length - 1)}
    # try {
    #   Get-VMPoolerStatus -URL $URL | Out-Null
    # }
    # catch {
    #   Write-Error "Could not connect to VMPooler at $url"
    #   return
    # }

    # $Script:VMPoolerServiceURI = $URL

    # if ($Credential -ne [System.Management.Automation.PSCredential]::Empty) {
    #   $Script:VMPoolCredential = $Credential
    # }


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
      (Get-WPFControl 'xmlPoolerDetail' -Window $thisWindow).Document = (Get-VMPoolerAllVMsAsXML)
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
            -ArgumentList @('-NoExit',"`"& { Enter-PSSession -Computername '$($vm.FQDN)' -Credential Administrator }`"") `
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

    if ($Credential -ne [System.Management.Automation.PSCredential]::Empty) {
      Connect-VMPooler -URL $URL -Credential $Credential | Out-Null
    } else {
      Connect-VMPooler -URL $URL | Out-Null
    }
    # Write the xml document to the XAML for databinding
    (Get-WPFControl 'xmlPoolList' -Window $thisWindow).Document = (Get-VMPoolerPoolAsXML)
    (Get-WPFControl 'xmlPoolerDetail' -Window $thisWindow).Document = (Get-VMPoolerAllVMsAsXML)

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