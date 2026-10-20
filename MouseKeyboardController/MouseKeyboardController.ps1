Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class MKCNative {
 [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X; public int Y; }
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")] public static extern bool GetCursorPos(out POINT p);
 [DllImport("user32.dll")] public static extern void mouse_event(uint flags,int dx,int dy,int data,UIntPtr extra);
 [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int key);
}
"@
# Small dialog that captures the next key press (including arrows, Tab, Enter, modifiers).
Add-Type -ReferencedAssemblies System.Windows.Forms,System.Drawing -TypeDefinition @"
using System;
using System.Windows.Forms;
public class MKCCaptureForm : Form {
 public int CapturedVk = 0;
 protected override bool ProcessCmdKey(ref Message msg, Keys keyData) {
  Keys k = keyData & Keys.KeyCode;
  if (k == Keys.Escape) { this.DialogResult = DialogResult.Cancel; this.Close(); return true; }
  CapturedVk = (int)k;
  this.DialogResult = DialogResult.OK;
  this.Close();
  return true;
 }
}
"@

# ---------------------------------------------------------------- state
$script:exe=''; $script:proc=$null; $script:enabled=$true; $script:drag=$false
$script:prev=@{}; $script:held=@{}; $script:resync=$false; $script:capturing=$false; $script:loading=$false
$script:accX=0.0; $script:accY=0.0; $script:lastScroll=0
$script:combos=@{}; $script:bars=@{}; $script:vals=@{}
$script:profile=$null; $script:dirty=$false
$script:vk=@{}
$TICKS_PER_SEC=62.5

# Mouse button table: down flag, up flag, data
$script:btn=@{ LeftClick=@(2,4,0); LeftClick2=@(2,4,0); RightClick=@(8,16,0); MiddleClick=@(32,64,0); Mouse4=@(128,256,1); Mouse5=@(128,256,2) }

# ---------------------------------------------------------------- key table
$script:KeyOrder=New-Object System.Collections.ArrayList
$script:LabelToVk=@{}
$script:VkToLabel=@{}
function AddKey([string]$label,[int]$vk){
 if($script:LabelToVk.ContainsKey($label)){return}
 $script:LabelToVk[$label]=$vk
 if(-not $script:VkToLabel.ContainsKey($vk)){$script:VkToLabel[$vk]=$label}
 [void]$script:KeyOrder.Add($label)
}
AddKey '(none)' 0
foreach($c in 65..90){AddKey ([string][char]$c) $c}
foreach($c in 48..57){AddKey ([string][char]$c) $c}
foreach($n in 1..12){AddKey "F$n" (111+$n)}
$named=@(@('Up',38),@('Down',40),@('Left',37),@('Right',39),@('Enter',13),@('Space',32),@('Backspace',8),@('Tab',9),@('Esc',27),@('Insert',45),@('Delete',46),@('Home',36),@('End',35),@('Page Up',33),@('Page Down',34),@('Caps Lock',20),@('Shift',16),@('Ctrl',17),@('Alt',18),@('Left Shift',160),@('Right Shift',161),@('Left Ctrl',162),@('Right Ctrl',163),@('Left Alt',164),@('Right Alt',165),@(';',186),@('=',187),@(',',188),@('-',189),@('.',190),@('/',191),@('`',192),@('[',219),@('\',220),@(']',221),@("'",222))
foreach($p in $named){AddKey $p[0] $p[1]}
foreach($n in 0..9){AddKey "Numpad $n" (96+$n)}
AddKey 'Numpad *' 106; AddKey 'Numpad +' 107; AddKey 'Numpad -' 109; AddKey 'Numpad .' 110; AddKey 'Numpad /' 111

function AddComboItem([string]$l){ foreach($cb in $script:combos.Values){ if(-not $cb.Items.Contains($l)){[void]$cb.Items.Add($l)} } }
function KeyLabel([int]$vk){
 if($script:VkToLabel.ContainsKey($vk)){return $script:VkToLabel[$vk]}
 $l='Key 0x{0:X2}' -f $vk
 AddKey $l $vk
 AddComboItem $l
 return $l
}
function KeyVk([string]$label){
 if($script:LabelToVk.ContainsKey($label)){return [int]$script:LabelToVk[$label]}
 if($label -match '^Key 0x([0-9A-Fa-f]{1,2})$'){ $v=[Convert]::ToInt32($Matches[1],16); [void](KeyLabel $v); return $v }
 return -1
}

# ---------------------------------------------------------------- actions and defaults
$script:Actions=@(
 @{Id='MoveUp';Text='Move up';Group='MOUSE MOVEMENT';Def='Up'},
 @{Id='MoveDown';Text='Move down';Group='MOUSE MOVEMENT';Def='Down'},
 @{Id='MoveLeft';Text='Move left';Group='MOUSE MOVEMENT';Def='Left'},
 @{Id='MoveRight';Text='Move right';Group='MOUSE MOVEMENT';Def='Right'},
 @{Id='Fast';Text='Fast move (hold)';Group='SPEED MODIFIERS';Def='Shift'},
 @{Id='Fine';Text='Fine aim (hold)';Group='SPEED MODIFIERS';Def='Ctrl'},
 @{Id='LeftClick';Text='Left click';Group='MOUSE BUTTONS';Def='Enter'},
 @{Id='LeftClick2';Text='Left click (second key)';Group='MOUSE BUTTONS';Def='Space'},
 @{Id='RightClick';Text='Right click';Group='MOUSE BUTTONS';Def='Backspace'},
 @{Id='MiddleClick';Text='Middle click';Group='MOUSE BUTTONS';Def='(none)'},
 @{Id='Mouse4';Text='Mouse 4 (back)';Group='MOUSE BUTTONS';Def='(none)'},
 @{Id='Mouse5';Text='Mouse 5 (forward)';Group='MOUSE BUTTONS';Def='(none)'},
 @{Id='ScrollUp';Text='Scroll wheel up';Group='SCROLL AND DRAG';Def='(none)'},
 @{Id='ScrollDown';Text='Scroll wheel down';Group='SCROLL AND DRAG';Def='(none)'},
 @{Id='DragHold';Text='Hold left button (drag)';Group='SCROLL AND DRAG';Def='Numpad 0'},
 @{Id='DragRelease';Text='Release left button';Group='SCROLL AND DRAG';Def='Numpad .'},
 @{Id='Toggle';Text='Toggle controller on/off';Group='CONTROLLER';Def='F7'},
 @{Id='ShowControls';Text='Show controls (window focused)';Group='CONTROLLER';Def='F6'}
)
$script:ActionIds=@(); foreach($a in $script:Actions){$script:ActionIds+=$a.Id}

function NewCfg {
 $b=@{}; foreach($a in $script:Actions){$b[$a.Id]=$a.Def}
 return @{Bindings=$b;SensX=16;SensY=16;LinkXY=$false;FastMult=2.5;FineSens=20;HoldMode=$false;Relative=$false}
}
$script:cfg=NewCfg

function RebuildVk { $script:vk=@{}; foreach($id in $script:ActionIds){$script:vk[$id]=KeyVk $script:cfg.Bindings[$id]} }
function KeyDown([string]$id){
 $k=$script:vk[$id]
 if(-not $k -or $k -le 0){return $false}
 return (([MKCNative]::GetAsyncKeyState([int]$k) -band 0x8000) -ne 0)
}

# ---------------------------------------------------------------- mouse output
function MouseEv([uint32]$flags,[int]$data){ [MKCNative]::mouse_event($flags,0,0,$data,[UIntPtr]::Zero) }
function MoveMouse([int]$dx,[int]$dy){
 if($script:cfg.Relative){ [MKCNative]::mouse_event(1,$dx,$dy,0,[UIntPtr]::Zero); return }
 $p=New-Object MKCNative+POINT
 [void][MKCNative]::GetCursorPos([ref]$p)
 $b=[Windows.Forms.SystemInformation]::VirtualScreen
 $x=[Math]::Max($b.Left,[Math]::Min($b.Right-1,$p.X+$dx))
 $y=[Math]::Max($b.Top,[Math]::Min($b.Bottom-1,$p.Y+$dy))
 [void][MKCNative]::SetCursorPos($x,$y)
}
function Drag([bool]$v){
 if($v -and -not $script:drag){MouseEv 2 0;$script:drag=$true}
 elseif(-not $v -and $script:drag){MouseEv 4 0;$script:drag=$false}
}
function ReleaseAll {
 foreach($id in @($script:held.Keys)){ if($script:held[$id]){ $d=$script:btn[$id]; MouseEv $d[1] $d[2]; $script:held[$id]=$false } }
 Drag $false
}

# ---------------------------------------------------------------- UI helpers
$cBg=[Drawing.Color]::FromArgb(24,28,36); $cPanel=[Drawing.Color]::FromArgb(32,38,49); $cAccent=[Drawing.Color]::FromArgb(110,190,255)
$cBtn=[Drawing.Color]::FromArgb(54,65,82); $cInput=[Drawing.Color]::FromArgb(45,52,66); $cMuted=[Drawing.Color]::FromArgb(150,160,175)
function NewLabel($parent,[string]$text,[int]$x,[int]$y,[int]$w,[int]$h,[double]$size=10,$color=$null){
 $l=New-Object Windows.Forms.Label; $l.Text=$text; $l.Location=New-Object Drawing.Point($x,$y); $l.Size=New-Object Drawing.Size($w,$h)
 if($null -eq $color){$color=[Drawing.Color]::White}
 $l.ForeColor=$color; $l.BackColor=[Drawing.Color]::Transparent; $l.Font=New-Object Drawing.Font('Segoe UI',[single]$size)
 $parent.Controls.Add($l); return $l
}
function NewButton($parent,[string]$text,[int]$x,[int]$y,[int]$w,[int]$h){
 $b=New-Object Windows.Forms.Button; $b.Text=$text; $b.Location=New-Object Drawing.Point($x,$y); $b.Size=New-Object Drawing.Size($w,$h)
 $b.FlatStyle='Flat'; $b.FlatAppearance.BorderSize=0; $b.BackColor=$cBtn; $b.ForeColor='White'; $b.Font=New-Object Drawing.Font('Segoe UI Semibold',9)
 $parent.Controls.Add($b); return $b
}
function NewCheck($parent,[string]$text,[int]$x,[int]$y,[int]$w){
 $c=New-Object Windows.Forms.CheckBox; $c.Text=$text; $c.Location=New-Object Drawing.Point($x,$y); $c.Size=New-Object Drawing.Size($w,26)
 $c.ForeColor='White'; $c.BackColor=[Drawing.Color]::Transparent; $c.Font=New-Object Drawing.Font('Segoe UI',9.5)
 $parent.Controls.Add($c); return $c
}
function SetBar([string]$k,[int]$v){
 $old=$script:loading; $script:loading=$true
 $b=$script:bars[$k]; $b.Value=[Math]::Max($b.Minimum,[Math]::Min($b.Maximum,$v))
 $script:loading=$old
}
function UpdateSliderLabels {
 $c=$script:cfg
 $script:vals['SensX'].Text=('{0} px per tick (about {1:0} px/sec)' -f $c.SensX,($c.SensX*$TICKS_PER_SEC))
 $script:vals['SensY'].Text=('{0} px per tick (about {1:0} px/sec)' -f $c.SensY,($c.SensY*$TICKS_PER_SEC))
 $script:vals['FastMult'].Text=('x{0:0.0} normal speed' -f $c.FastMult)
 $script:vals['FineSens'].Text=('{0}% of normal speed' -f $c.FineSens)
}
function BarChanged($s){
 if($script:loading){return}
 $c=$script:cfg; $k=[string]$s.Tag; $v=[int]$s.Value
 switch($k){
  'SensX'{$c.SensX=$v; if($c.LinkXY){SetBar 'SensY' $v; $c.SensY=$v}}
  'SensY'{$c.SensY=$v; if($c.LinkXY){SetBar 'SensX' $v; $c.SensX=$v}}
  'FastMult'{$c.FastMult=$v/10.0}
  'FineSens'{$c.FineSens=$v}
 }
 UpdateSliderLabels; MarkDirty
}
function NewBar($parent,[string]$key,[string]$title,[int]$y,[int]$min,[int]$max){
 NewLabel $parent $title 10 $y 380 22 9.5 | Out-Null
 $b=New-Object Windows.Forms.TrackBar; $b.Minimum=$min; $b.Maximum=$max; $b.TickStyle='None'; $b.SmallChange=1; $b.LargeChange=5
 $b.Location=New-Object Drawing.Point(10,($y+22)); $b.Size=New-Object Drawing.Size(380,34); $b.BackColor=$cPanel; $b.Tag=$key
 $b.Add_ValueChanged({param($s,$e) BarChanged $s})
 $parent.Controls.Add($b)
 $v=NewLabel $parent '' 400 ($y+26) 165 36 9
 $script:bars[$key]=$b; $script:vals[$key]=$v
}

# ---------------------------------------------------------------- summary
function SummaryText {
 $c=$script:cfg; $sb=New-Object System.Text.StringBuilder
 $pn=if($script:profile){$script:profile}else{'(unsaved / defaults)'}
 if($script:dirty){$pn+='  [modified]'}
 [void]$sb.AppendLine('Profile: '+$pn)
 $lastGroup=''
 foreach($a in $script:Actions){
  if($a.Group -ne $lastGroup){ [void]$sb.AppendLine(''); [void]$sb.AppendLine($a.Group); $lastGroup=$a.Group }
  [void]$sb.AppendLine(('  {0,-30}{1}' -f $a.Text,$c.Bindings[$a.Id]))
 }
 [void]$sb.AppendLine(''); [void]$sb.AppendLine('SENSITIVITY (pixels per tick)')
 [void]$sb.AppendLine(('  {0,-30}{1}' -f 'Horizontal',$c.SensX))
 [void]$sb.AppendLine(('  {0,-30}{1}' -f 'Vertical',$c.SensY))
 [void]$sb.AppendLine(('  {0,-30}x{1:0.0}  ({2:0.#} / {3:0.#})' -f 'Fast move',$c.FastMult,($c.SensX*$c.FastMult),($c.SensY*$c.FastMult)))
 [void]$sb.AppendLine(('  {0,-30}{1}%  ({2:0.#} / {3:0.#})' -f 'Fine aim',$c.FineSens,($c.SensX*$c.FineSens/100.0),($c.SensY*$c.FineSens/100.0)))
 [void]$sb.AppendLine(''); [void]$sb.AppendLine('OPTIONS')
 $hm=if($c.HoldMode){'Hold while key is held'}else{'One click per key press'}
 $rm=if($c.Relative){'Relative (game mode)'}else{'Set cursor position'}
 [void]$sb.AppendLine(('  {0,-30}{1}' -f 'Mouse buttons',$hm))
 [void]$sb.AppendLine(('  {0,-30}{1}' -f 'Movement method',$rm))
 $use=@{}
 foreach($a in $script:Actions){ $l=$c.Bindings[$a.Id]; if($l -ne '(none)'){ if(-not $use.ContainsKey($l)){$use[$l]=@()}; $use[$l]+=$a.Text } }
 $warn=@(); foreach($l in $use.Keys){ if($use[$l].Count -gt 1){ $warn+=('  '+$l+': '+($use[$l] -join ', ')) } }
 if($warn.Count -gt 0){ [void]$sb.AppendLine(''); [void]$sb.AppendLine('WARNING - key used twice:'); foreach($w in $warn){[void]$sb.AppendLine($w)} }
 return $sb.ToString()
}
function RefreshSummary { if($script:summaryBox){ $script:summaryBox.Text=(SummaryText) } }
function MarkDirty { $script:dirty=$true; RefreshSummary }

# ---------------------------------------------------------------- apply config to UI
function ApplyCfgToUi {
 $script:loading=$true
 $c=$script:cfg
 foreach($id in $script:ActionIds){ [void](KeyVk $c.Bindings[$id]); $script:combos[$id].SelectedItem=$c.Bindings[$id] }
 $script:loading=$false
 SetBar 'SensX' $c.SensX; SetBar 'SensY' $c.SensY; SetBar 'FastMult' ([int][Math]::Round($c.FastMult*10)); SetBar 'FineSens' $c.FineSens
 $script:loading=$true
 $script:chkLink.Checked=[bool]$c.LinkXY; $script:chkHold.Checked=[bool]$c.HoldMode; $script:chkRel.Checked=[bool]$c.Relative
 $script:loading=$false
 RebuildVk; UpdateSliderLabels; RefreshSummary
}

# ---------------------------------------------------------------- profiles
$root=$PSScriptRoot; if(-not $root){$root=Split-Path -Parent $MyInvocation.MyCommand.Path}
$script:profDir=Join-Path $root 'Profiles'
try{ if(-not (Test-Path -LiteralPath $script:profDir)){ New-Item -ItemType Directory -Path $script:profDir -ErrorAction Stop | Out-Null } }catch{}
function ProfilePath([string]$name){ return (Join-Path $script:profDir (($name -replace '[\\/:*?"<>|]','_')+'.json')) }
function RefreshProfileList {
 $script:cbProfile.Items.Clear()
 $files=Get-ChildItem -LiteralPath $script:profDir -Filter *.json -ErrorAction SilentlyContinue | Sort-Object Name
 foreach($f in $files){ [void]$script:cbProfile.Items.Add($f.BaseName) }
}
function CfgFromObject($j){
 $c=NewCfg
 if($j.Bindings){ foreach($a in $script:Actions){ $p=$j.Bindings.PSObject.Properties[$a.Id]; if($p){ $l=[string]$p.Value; if((KeyVk $l) -ge 0){$c.Bindings[$a.Id]=$l} } } }
 foreach($n in 'SensX','SensY'){ if($null -ne $j.$n){ $c[$n]=[Math]::Max(1,[Math]::Min(60,[int]$j.$n)) } }
 if($null -ne $j.FastMult){ $c.FastMult=[Math]::Max(1.1,[Math]::Min(8.0,[double]$j.FastMult)) }
 if($null -ne $j.FineSens){ $c.FineSens=[Math]::Max(5,[Math]::Min(100,[int]$j.FineSens)) }
 foreach($n in 'LinkXY','HoldMode','Relative'){ if($null -ne $j.$n){ $c[$n]=[bool]$j.$n } }
 return $c
}
function SaveProfile {
 $name=$script:cbProfile.Text.Trim()
 if(-not $name){ [Windows.Forms.MessageBox]::Show('Type a profile name first (for example the game name).','Save profile')|Out-Null; return }
 $safe=($name -replace '[\\/:*?"<>|]','_'); $path=ProfilePath $safe
 if((Test-Path -LiteralPath $path) -and $script:profile -ne $safe){
  if([Windows.Forms.MessageBox]::Show("Profile '$safe' already exists. Overwrite it?",'Save profile','YesNo','Question') -ne 'Yes'){return}
 }
 try{
  $c=$script:cfg
  $o=[ordered]@{Name=$safe;Version=1;Bindings=[ordered]@{}}
  foreach($a in $script:Actions){$o.Bindings[$a.Id]=$c.Bindings[$a.Id]}
  $o.SensX=$c.SensX; $o.SensY=$c.SensY; $o.LinkXY=[bool]$c.LinkXY; $o.FastMult=$c.FastMult; $o.FineSens=$c.FineSens
  $o.HoldMode=[bool]$c.HoldMode; $o.Relative=[bool]$c.Relative; $o.AppPath=$script:exe
  $o | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $path -Encoding UTF8
  Set-Content -LiteralPath (Join-Path $script:profDir '_last.txt') -Value $safe -Encoding ASCII
  $script:profile=$safe; $script:dirty=$false
  RefreshProfileList; $script:cbProfile.Text=$safe; RefreshSummary; RefreshStatus
 }catch{ [Windows.Forms.MessageBox]::Show($_.Exception.Message,'Save error')|Out-Null }
}
function LoadProfile([string]$name){
 $path=ProfilePath $name
 if(-not (Test-Path -LiteralPath $path)){ [Windows.Forms.MessageBox]::Show("Profile '$name' was not found.",'Load profile')|Out-Null; return }
 try{
  $j=Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
  ReleaseAll
  $script:cfg=CfgFromObject $j
  if($j.AppPath){ $script:exe=[string]$j.AppPath }
  ApplyCfgToUi
  $script:profile=$name; $script:dirty=$false
  try{ Set-Content -LiteralPath (Join-Path $script:profDir '_last.txt') -Value $name -Encoding ASCII }catch{}
  $script:cbProfile.Text=$name; RefreshSummary; RefreshStatus
 }catch{ [Windows.Forms.MessageBox]::Show($_.Exception.Message,'Load error')|Out-Null }
}
function DeleteProfile {
 $name=$script:cbProfile.Text.Trim(); $path=ProfilePath $name
 if(-not $name -or -not (Test-Path -LiteralPath $path)){ [Windows.Forms.MessageBox]::Show('Pick an existing profile to delete.','Delete profile')|Out-Null; return }
 if([Windows.Forms.MessageBox]::Show("Delete profile '$name'?",'Delete profile','YesNo','Warning') -ne 'Yes'){return}
 try{ Remove-Item -LiteralPath $path -ErrorAction Stop; if($script:profile -eq $name){$script:profile=$null}; RefreshProfileList; $script:cbProfile.Text=''; RefreshSummary }
 catch{ [Windows.Forms.MessageBox]::Show($_.Exception.Message,'Delete error')|Out-Null }
}

# ---------------------------------------------------------------- main window
$form=New-Object Windows.Forms.Form; $form.Text='Mouse + Keyboard Controller'; $form.ClientSize=New-Object Drawing.Size(960,684); $form.StartPosition='CenterScreen'
$form.FormBorderStyle='FixedSingle'; $form.MaximizeBox=$false; $form.BackColor=$cBg; $form.ForeColor=[Drawing.Color]::White; $form.Font=New-Object Drawing.Font('Segoe UI',10); $form.KeyPreview=$true

NewLabel $form 'MOUSE + KEYBOARD CONTROLLER' 24 14 600 34 17 $cAccent | Out-Null
NewLabel $form 'Choose a Windows app, launch it, then use your keyboard as a mouse.' 26 49 700 24 9.5 ([Drawing.Color]::Gainsboro) | Out-Null
$browse=NewButton $form 'Choose .EXE...' 26 82 145 38; $launch=NewButton $form 'Launch selected app' 180 82 180 38; $stop=NewButton $form 'Stop app' 369 82 105 38
$toggle=NewButton $form 'Keyboard control: ON' 483 82 240 38
$exeLabel=NewLabel $form 'No app selected' 28 126 880 22 10 ([Drawing.Color]::LightSteelBlue); $status=NewLabel $form 'App status: Not running' 28 148 880 22 10 ([Drawing.Color]::LightSteelBlue)

$tabs=New-Object Windows.Forms.TabControl; $tabs.Location=New-Object Drawing.Point(24,178); $tabs.Size=New-Object Drawing.Size(584,440); $form.Controls.Add($tabs)
function NewTab([string]$title){
 $t=New-Object Windows.Forms.TabPage; $t.Text=$title; $t.UseVisualStyleBackColor=$false; $t.BackColor=$cPanel
 $p=New-Object Windows.Forms.Panel; $p.Dock='Fill'; $p.AutoScroll=$true; $p.BackColor=$cPanel; $t.Controls.Add($p); $tabs.TabPages.Add($t)
 return $p
}
$tabKeys=NewTab 'Key bindings'; $tabSens=NewTab 'Sensitivity'; $tabProf=NewTab 'Profiles'

# ---- Key bindings tab
$y=8; $lastGroup=''
foreach($a in $script:Actions){
 if($a.Group -ne $lastGroup){ if($lastGroup){$y+=6}; NewLabel $tabKeys $a.Group 10 $y 400 22 9 $cAccent | Out-Null; $y+=26; $lastGroup=$a.Group }
 NewLabel $tabKeys $a.Text 14 ($y+3) 200 22 9.5 | Out-Null
 $cb=New-Object Windows.Forms.ComboBox; $cb.DropDownStyle='DropDownList'; $cb.FlatStyle='Flat'; $cb.BackColor=$cInput; $cb.ForeColor='White'
 $cb.Location=New-Object Drawing.Point(220,$y); $cb.Size=New-Object Drawing.Size(180,26); $cb.MaxDropDownItems=14; $cb.Tag=$a.Id
 foreach($l in $script:KeyOrder){[void]$cb.Items.Add($l)}
 $cb.Add_MouseWheel({param($s,$e) $e.Handled=$true})
 $cb.Add_SelectedIndexChanged({param($s,$e)
  if($script:loading -or $null -eq $s.SelectedItem){return}
  $script:cfg.Bindings[[string]$s.Tag]=[string]$s.SelectedItem
  RebuildVk; MarkDirty
 })
 $tabKeys.Controls.Add($cb); $script:combos[$a.Id]=$cb
 $cap=NewButton $tabKeys 'Press a key...' 408 ($y-1) 110 28; $cap.Tag=$a.Id
 $cap.Add_Click({param($s,$e)
  $id=[string]$s.Tag; $txt=''; foreach($x in $script:Actions){if($x.Id -eq $id){$txt=$x.Text}}
  $dlg=New-Object MKCCaptureForm
  $dlg.Text='Press a key'; $dlg.ClientSize=New-Object Drawing.Size(380,130); $dlg.StartPosition='CenterParent'; $dlg.FormBorderStyle='FixedDialog'
  $dlg.MaximizeBox=$false; $dlg.MinimizeBox=$false; $dlg.ShowInTaskbar=$false; $dlg.BackColor=$cBg; $dlg.ForeColor=[Drawing.Color]::White; $dlg.Font=New-Object Drawing.Font('Segoe UI',10)
  NewLabel $dlg ('Press the key to use for:') 20 18 340 24 10 | Out-Null
  NewLabel $dlg $txt 20 44 340 28 14 $cAccent | Out-Null
  NewLabel $dlg 'Esc = cancel   (choose "(none)" in the list to clear a key)' 20 90 340 22 9 ([Drawing.Color]::Gainsboro) | Out-Null
  $script:capturing=$true
  $r=$dlg.ShowDialog($form)
  $script:capturing=$false; $script:resync=$true
  if($r -eq 'OK' -and $dlg.CapturedVk -gt 0){ $lab=KeyLabel $dlg.CapturedVk; $script:combos[$id].SelectedItem=$lab }
  $dlg.Dispose()
 })
 $y+=32
}

# ---- Sensitivity tab
NewBar $tabSens 'SensX' 'Horizontal sensitivity (left / right)' 8 1 60
NewBar $tabSens 'SensY' 'Vertical sensitivity (up / down)' 72 1 60
$script:chkLink=NewCheck $tabSens 'Keep horizontal and vertical the same' 10 134 540
NewBar $tabSens 'FastMult' 'Fast-move multiplier (while the Fast key is held)' 166 11 80
NewBar $tabSens 'FineSens' 'Fine-aim sensitivity (while the Fine-aim key is held)' 230 5 100
$script:chkHold=NewCheck $tabSens 'Hold mouse button while its key is held (instead of one click per press)' 10 298 550
$script:chkRel=NewCheck $tabSens 'Game mode: relative mouse movement (try this if a game ignores the pointer)' 10 326 550
NewLabel $tabSens 'Sensitivity is pixels per tick (about 62 ticks per second). Fine aim slows the pointer to a percentage of normal speed for precise targeting. If both Fast and Fine keys are held, Fine aim wins.' 10 360 550 44 9 $cMuted | Out-Null
$script:chkLink.Add_CheckedChanged({
 if($script:loading){return}
 $script:cfg.LinkXY=$script:chkLink.Checked
 if($script:chkLink.Checked){ $script:cfg.SensY=$script:cfg.SensX; SetBar 'SensY' $script:cfg.SensX; UpdateSliderLabels }
 MarkDirty
})
$script:chkHold.Add_CheckedChanged({ if($script:loading){return}; ReleaseAll; $script:cfg.HoldMode=$script:chkHold.Checked; MarkDirty })
$script:chkRel.Add_CheckedChanged({ if($script:loading){return}; $script:cfg.Relative=$script:chkRel.Checked; MarkDirty })

# ---- Profiles tab
NewLabel $tabProf 'Profile name (pick one, or type a new name such as a game title)' 10 12 540 22 9.5 | Out-Null
$script:cbProfile=New-Object Windows.Forms.ComboBox; $script:cbProfile.DropDownStyle='DropDown'; $script:cbProfile.BackColor=$cInput; $script:cbProfile.ForeColor='White'
$script:cbProfile.Location=New-Object Drawing.Point(10,38); $script:cbProfile.Size=New-Object Drawing.Size(270,26); $tabProf.Controls.Add($script:cbProfile)
$bSave=NewButton $tabProf 'Save' 290 35 80 30; $bLoad=NewButton $tabProf 'Load' 376 35 80 30; $bDel=NewButton $tabProf 'Delete' 462 35 80 30
NewLabel $tabProf 'A profile stores your key bindings, sensitivity, options and the selected app (.exe), so each game can have its own setup. Save under the same name to update a profile.' 10 82 540 56 9.5 $cMuted | Out-Null
NewLabel $tabProf 'Profiles are saved as small .json files in:' 10 148 540 22 9.5 | Out-Null
NewLabel $tabProf $script:profDir 10 170 540 40 9 $cAccent | Out-Null
$bFolder=NewButton $tabProf 'Open profiles folder' 10 214 170 30
$bSave.Add_Click({SaveProfile})
$bLoad.Add_Click({ $n=$script:cbProfile.Text.Trim(); if(-not $n){[Windows.Forms.MessageBox]::Show('Pick a profile to load.','Load profile')|Out-Null}else{LoadProfile $n} })
$bDel.Add_Click({DeleteProfile})
$bFolder.Add_Click({ try{ Start-Process explorer.exe -ArgumentList ('"'+$script:profDir+'"') }catch{} })

# ---- summary panel
$sp=New-Object Windows.Forms.Panel; $sp.Location=New-Object Drawing.Point(620,178); $sp.Size=New-Object Drawing.Size(316,440); $sp.BackColor=$cPanel; $form.Controls.Add($sp)
NewLabel $sp 'LIVE CONFIGURATION SUMMARY' 12 8 290 22 10 $cAccent | Out-Null
$script:summaryBox=New-Object Windows.Forms.TextBox; $script:summaryBox.Multiline=$true; $script:summaryBox.ReadOnly=$true; $script:summaryBox.ScrollBars='Vertical'
$script:summaryBox.BorderStyle='None'; $script:summaryBox.BackColor=[Drawing.Color]::FromArgb(20,24,31); $script:summaryBox.ForeColor=[Drawing.Color]::Gainsboro
$script:summaryBox.Font=New-Object Drawing.Font('Consolas',9); $script:summaryBox.Location=New-Object Drawing.Point(10,34); $script:summaryBox.Size=New-Object Drawing.Size(296,396); $sp.Controls.Add($script:summaryBox)

# ---- bottom bar
$reset=NewButton $form 'Reset to defaults' 24 632 190 38; $reset.BackColor=[Drawing.Color]::FromArgb(145,65,65)
NewLabel $form 'Keep this window open while using the selected app. No downloads or third-party installs required.' 230 641 700 22 9.5 ([Drawing.Color]::Gainsboro) | Out-Null

# ---------------------------------------------------------------- behaviour
function RefreshStatus {
 if($script:exe){$exeLabel.Text='Selected app: '+[IO.Path]::GetFileName($script:exe)}else{$exeLabel.Text='No app selected'}
 if($script:proc){ try{ if(-not $script:proc.HasExited){$status.Text="App status: Running (PID $($script:proc.Id))"}else{$script:proc=$null;$status.Text='App status: Not running'} }catch{$status.Text='App status: Not running'} }else{$status.Text='App status: Not running'}
 $toggle.Text=if($script:enabled){'Keyboard control: ON'}else{'Keyboard control: OFF'}
 $toggle.BackColor=if($script:enabled){[Drawing.Color]::FromArgb(35,145,95)}else{[Drawing.Color]::FromArgb(145,65,65)}
}
function SetEnabled([bool]$v){ $script:enabled=$v; if(-not $v){ReleaseAll}; RefreshStatus }

$browse.Add_Click({$d=New-Object Windows.Forms.OpenFileDialog;$d.Title='Select the application executable';$d.Filter='Windows executable (*.exe)|*.exe|All files (*.*)|*.*';$d.CheckFileExists=$true;if($d.ShowDialog() -eq 'OK'){$script:exe=$d.FileName;if($script:profile){MarkDirty};RefreshStatus}})
$launch.Add_Click({if(-not $script:exe -or -not(Test-Path -LiteralPath $script:exe)){[Windows.Forms.MessageBox]::Show('Choose a valid .exe first.','No app selected')|Out-Null;return};try{$script:proc=Start-Process -FilePath $script:exe -WorkingDirectory (Split-Path -Parent $script:exe) -PassThru;RefreshStatus}catch{[Windows.Forms.MessageBox]::Show($_.Exception.Message,'Launch error')|Out-Null}})
$stop.Add_Click({if($script:proc){try{Stop-Process -Id $script:proc.Id -ErrorAction Stop}catch{}};RefreshStatus})
$toggle.Add_Click({SetEnabled (-not $script:enabled)})
$reset.Add_Click({
 if([Windows.Forms.MessageBox]::Show('Restore all key bindings, sensitivity and options to the original defaults?','Reset to defaults','YesNo','Question') -eq 'Yes'){
  ReleaseAll; $script:cfg=NewCfg; ApplyCfgToUi; MarkDirty
 }
})
$form.Add_KeyDown({param($s,$e)
 if($script:capturing){return}
 $v=$script:vk['ShowControls']
 if($v -and $e.KeyValue -eq $v){ [Windows.Forms.MessageBox]::Show((SummaryText),'Keyboard controls')|Out-Null; $e.Handled=$true }
})

$timer=New-Object Windows.Forms.Timer; $timer.Interval=16
$timer.Add_Tick({
 if($script:capturing){return}
 $now=@{}
 foreach($id in $script:ActionIds){$now[$id]=(KeyDown $id)}
 if($script:resync){$script:prev=$now;$script:resync=$false;return}
 $pressed=@{}; $released=@{}
 foreach($id in $script:ActionIds){ $o=[bool]$script:prev[$id]; $pressed[$id]=($now[$id] -and -not $o); $released[$id]=((-not $now[$id]) -and $o) }
 $script:prev=$now
 if($pressed['Toggle']){ SetEnabled (-not $script:enabled) }
 if(-not $script:enabled){ if($script:proc){try{if($script:proc.HasExited){RefreshStatus}}catch{}}; return }
 $c=$script:cfg

 # movement
 $dx=0; $dy=0
 if($now['MoveLeft']){$dx-=1}; if($now['MoveRight']){$dx+=1}; if($now['MoveUp']){$dy-=1}; if($now['MoveDown']){$dy+=1}
 if($dx -ne 0 -or $dy -ne 0){
  $mx=[double]$c.SensX; $my=[double]$c.SensY
  if($now['Fine']){ $f=$c.FineSens/100.0; $mx*=$f; $my*=$f } elseif($now['Fast']){ $mx*=$c.FastMult; $my*=$c.FastMult }
  $script:accX+=$dx*$mx; $script:accY+=$dy*$my
  $ix=[int][Math]::Truncate($script:accX); $iy=[int][Math]::Truncate($script:accY)
  $script:accX-=$ix; $script:accY-=$iy
  if($ix -ne 0 -or $iy -ne 0){ MoveMouse $ix $iy }
 } else { $script:accX=0.0; $script:accY=0.0 }

 # mouse buttons
 foreach($id in 'LeftClick','LeftClick2','RightClick','MiddleClick','Mouse4','Mouse5'){
  $d=$script:btn[$id]
  if($pressed[$id]){
   MouseEv $d[0] $d[2]
   if($c.HoldMode){$script:held[$id]=$true}else{MouseEv $d[1] $d[2]}
  } elseif($released[$id] -and $script:held[$id]){
   MouseEv $d[1] $d[2]; $script:held[$id]=$false
  }
 }

 # drag
 if($pressed['DragHold']){Drag $true}
 if($pressed['DragRelease']){Drag $false}

 # scroll wheel (repeats while held)
 $t=[Environment]::TickCount
 if(($now['ScrollUp'] -or $now['ScrollDown']) -and ($t-$script:lastScroll) -ge 60){
  if($now['ScrollUp']){MouseEv 2048 120}else{MouseEv 2048 (-120)}
  $script:lastScroll=$t
 }

 if($script:proc){try{if($script:proc.HasExited){RefreshStatus}}catch{}}
})
$form.Add_FormClosing({ReleaseAll;$timer.Stop()})

# ---------------------------------------------------------------- startup
RefreshProfileList
ApplyCfgToUi
$lastFile=Join-Path $script:profDir '_last.txt'
if(Test-Path -LiteralPath $lastFile){ try{ $ln=(Get-Content -LiteralPath $lastFile -ErrorAction Stop | Select-Object -First 1).Trim(); if($ln -and (Test-Path -LiteralPath (ProfilePath $ln))){ LoadProfile $ln } }catch{} }
RefreshStatus
$timer.Start()
[void]$form.ShowDialog()
