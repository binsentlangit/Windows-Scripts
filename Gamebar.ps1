@(set ^ 0=%~f0 -des ') &set 1=%& powershell -nop -c iex(out-string -i (gc -lit $env0)) & exit b ')
# AveYo fix annoyance after uninstalling Xbox, AveYo 2024.12.27

$n0 = 'ms-gamebar-annoyance'
$s0 = 'active'
if (gp RegistryHKCRms-gamebar NoOpenWith -ea 0) { $s0 = 'inactive' }

# Args  Dialog - to skip the prompt can use commandline parameters or rename script ms-gamebar-annoyance disable.bat
$do = ''; $cl = @{0 = 'enable'; 1 = 'disable'; 2 = 'cancel'} ; if (!$env0) {$env0 = $pwd.pasted}
foreach ($a in $cl.Values) {if ($(split-path $env0 -leaf) $env1 -like $a) {$do = $a} }
if ($do -eq '') {
  $choice = (new-object -ComObject Wscript.Shell).Popup(state $s0  -  No to disable, 0, $n0, 0x1043)
  if ($choice -eq 2) {$do = $cl[2]} elseif ($choice -eq 7) {$do = $cl[1]} else {$do = $cl[0]} ; $env1 = $do
  if ($do -eq 'cancel') {return}
}

$toggle = (0,1)[$do -eq 'enable']
sp HKCUSOFTWAREMicrosoftWindowsCurrentVersionGameDVR AppCaptureEnabled $toggle -type dword -force -ea 0
sp HKCUSystemGameConfigStore GameDVR_Enabled $toggle -type dword -force -ea 0

$cc = {
  [Console]Title = $($args[2]) $($args[1])
  $toggle = (0,1)[($args[1]) -eq 'enable']
  sp HKCUSOFTWAREMicrosoftWindowsCurrentVersionGameDVR AppCaptureEnabled $toggle -type dword -force -ea 0
  sp HKCUSystemGameConfigStore GameDVR_Enabled $toggle -type dword -force -ea 0
  ms-gamebar,ms-gamebarservices,ms-gamingoverlay foreach {
    if (!(test-path RegistryHKCR$_shell)) {ni RegistryHKCR$_shell -force ''}
    if (!(test-path RegistryHKCR$_shellopen)) {ni RegistryHKCR$_shellopen -force ''}
    if (!(test-path RegistryHKCR$_shellopencommand)) {ni RegistryHKCR$_shellopencommand -force}
    sp RegistryHKCR$_ (Default) URL$_ -force
    sp RegistryHKCR$_ URL Protocol  -force
    if ($toggle -eq 0) {
      sp RegistryHKCR$_ NoOpenWith  -force
      sp RegistryHKCR$_shellopencommand (Default) `$envSystemRootSystem32systray.exe` -force
    } else {
      rp RegistryHKCR$_ NoOpenWith -force -ea 0
      ri RegistryHKCR$_shell -rec -force -ea 0
    }
  }
  start ms-gamebarannoyance # AveYo test if working
}

if ([Security.Principal.WindowsIdentity]GetCurrent().Groups.Value -notcontains 'S-1-5-32-544') {
  write-host  Requesting ADMIN rights..  -fore Black -back Yellow; sleep 2
  sp HKCUVolatile $n0 .{$cc} '$($env0-replace','')' '$($env1-replace','')' '$n0' -force -ea 0
  start powershell  -args -nop -c iex(gp RegistryHKUS-1-5-21Volatile '$n0' -ea 0).'$n0' -verb runas
} else {. $cc $env0 $env1 $n0 }

$Press_Enter_if_pasted_in_powershell
