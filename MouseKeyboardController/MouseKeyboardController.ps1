Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class MKCNative {
 [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X; public int Y; }
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")] public static extern bool GetCursorPos(out POINT p);
 [DllImport("user32.dll")] public static extern void mouse_event(uint flags,uint dx,uint dy,uint data,UIntPtr extra);
 [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int key);
}
"@
$script:exe=''; $script:proc=$null; $script:enabled=$true; $script:drag=$false; $script:prev=@{}
$LEFTDOWN=2; $LEFTUP=4; $RIGHTDOWN=8; $RIGHTUP=16
function Down([int]$k){ return (([MKCNative]::GetAsyncKeyState($k) -band 0x8000) -ne 0) }
function LClick { [MKCNative]::mouse_event($LEFTDOWN,0,0,0,[UIntPtr]::Zero); [MKCNative]::mouse_event($LEFTUP,0,0,0,[UIntPtr]::Zero) }
function RClick { [MKCNative]::mouse_event($RIGHTDOWN,0,0,0,[UIntPtr]::Zero); [MKCNative]::mouse_event($RIGHTUP,0,0,0,[UIntPtr]::Zero) }
function Drag([bool]$v){ if($v -and -not $script:drag){[MKCNative]::mouse_event($LEFTDOWN,0,0,0,[UIntPtr]::Zero);$script:drag=$true} elseif(-not $v -and $script:drag){[MKCNative]::mouse_event($LEFTUP,0,0,0,[UIntPtr]::Zero);$script:drag=$false} }
$form=New-Object Windows.Forms.Form; $form.Text='Mouse + Keyboard Controller'; $form.Size=New-Object Drawing.Size(620,540); $form.StartPosition='CenterScreen'; $form.BackColor=[Drawing.Color]::FromArgb(24,28,36); $form.ForeColor=[Drawing.Color]::White; $form.Font=New-Object Drawing.Font('Segoe UI',10); $form.KeyPreview=$true
function Label($t,$x,$y,$w,$h,$size=10,$color=[Drawing.Color]::White){$l=New-Object Windows.Forms.Label;$l.Text=$t;$l.Location=New-Object Drawing.Point($x,$y);$l.Size=New-Object Drawing.Size($w,$h);$l.ForeColor=$color;$l.Font=New-Object Drawing.Font('Segoe UI',$size);$form.Controls.Add($l);return $l}
function Button($t,$x,$y,$w,$h){$b=New-Object Windows.Forms.Button;$b.Text=$t;$b.Location=New-Object Drawing.Point($x,$y);$b.Size=New-Object Drawing.Size($w,$h);$b.FlatStyle='Flat';$b.FlatAppearance.BorderSize=0;$b.BackColor=[Drawing.Color]::FromArgb(54,65,82);$b.ForeColor='White';$b.Font=New-Object Drawing.Font('Segoe UI Semibold',9);$form.Controls.Add($b);return $b}
Label 'MOUSE + KEYBOARD CONTROLLER' 24 18 560 34 17 ([Drawing.Color]::FromArgb(110,190,255))|Out-Null
Label 'Choose a Windows app, launch it, then use your keyboard as a mouse.' 26 53 560 28 9.5 ([Drawing.Color]::Gainsboro)|Out-Null
$browse=Button 'Choose .EXE...' 26 95 145 40; $launch=Button 'Launch selected app' 182 95 180 40; $stop=Button 'Stop app' 373 95 105 40; $toggle=Button 'Keyboard control: ON' 26 151 240 40; $toggle.BackColor=[Drawing.Color]::FromArgb(35,145,95)
$exeLabel=Label 'No app selected' 28 204 550 24 10 ([Drawing.Color]::LightSteelBlue); $status=Label 'App status: Not running' 28 229 550 24 10 ([Drawing.Color]::LightSteelBlue)
$panel=New-Object Windows.Forms.Panel;$panel.Location=New-Object Drawing.Point(26,266);$panel.Size=New-Object Drawing.Size(550,190);$panel.BackColor=[Drawing.Color]::FromArgb(32,38,49);$form.Controls.Add($panel)
$head=New-Object Windows.Forms.Label;$head.Text='KEYBOARD CONTROLS';$head.Location=New-Object Drawing.Point(15,10);$head.Size=New-Object Drawing.Size(300,22);$head.ForeColor=[Drawing.Color]::FromArgb(110,190,255);$head.Font=New-Object Drawing.Font('Segoe UI Semibold',10);$panel.Controls.Add($head)
$rows=@(@('Arrow keys','Move pointer'),@('Shift + arrows','Move faster'),@('Enter / Space','Left-click'),@('Backspace','Right-click'),@('Numpad 0','Hold left button to drag'),@('Numpad Decimal','Release drag'),@('F6','Show controls'),@('F7','Toggle controller'))
$y=38;foreach($r in $rows){$a=New-Object Windows.Forms.Label;$a.Text=$r[0];$a.Location=New-Object Drawing.Point(16,$y);$a.Size=New-Object Drawing.Size(145,19);$a.ForeColor='White';$a.Font=New-Object Drawing.Font('Consolas',9);$panel.Controls.Add($a);$d=New-Object Windows.Forms.Label;$d.Text=$r[1];$d.Location=New-Object Drawing.Point(166,$y);$d.Size=New-Object Drawing.Size(365,19);$d.ForeColor=[Drawing.Color]::Gainsboro;$d.Font=New-Object Drawing.Font('Segoe UI',9);$panel.Controls.Add($d);$y+=19}
Label 'Keep this window open while using the selected app.' 28 470 550 22 9.5 ([Drawing.Color]::Gainsboro)|Out-Null
Label 'No downloads or third-party installs required.' 28 493 550 20 9 ([Drawing.Color]::Gray)|Out-Null
function RefreshStatus { if($script:exe){$exeLabel.Text='Selected app: '+[IO.Path]::GetFileName($script:exe)}else{$exeLabel.Text='No app selected'};if($script:proc){try{if(-not $script:proc.HasExited){$status.Text="App status: Running (PID $($script:proc.Id))"}else{$script:proc=$null;$status.Text='App status: Not running'}}catch{$status.Text='App status: Not running'}}else{$status.Text='App status: Not running'};$toggle.Text=if($script:enabled){'Keyboard control: ON'}else{'Keyboard control: OFF'};$toggle.BackColor=if($script:enabled){[Drawing.Color]::FromArgb(35,145,95)}else{[Drawing.Color]::FromArgb(145,65,65)}}
$browse.Add_Click({$d=New-Object Windows.Forms.OpenFileDialog;$d.Title='Select the application executable';$d.Filter='Windows executable (*.exe)|*.exe|All files (*.*)|*.*';$d.CheckFileExists=$true;if($d.ShowDialog() -eq 'OK'){$script:exe=$d.FileName;RefreshStatus}})
$launch.Add_Click({if(-not $script:exe -or -not(Test-Path -LiteralPath $script:exe)){[Windows.Forms.MessageBox]::Show('Choose a valid .exe first.','No app selected')|Out-Null;return};try{$script:proc=Start-Process -FilePath $script:exe -WorkingDirectory (Split-Path -Parent $script:exe) -PassThru;RefreshStatus}catch{[Windows.Forms.MessageBox]::Show($_.Exception.Message,'Launch error')|Out-Null}})
$stop.Add_Click({if($script:proc){try{Stop-Process -Id $script:proc.Id -ErrorAction Stop}catch{}};RefreshStatus})
$toggle.Add_Click({$script:enabled=-not $script:enabled;if(-not $script:enabled){Drag $false};RefreshStatus})
$form.Add_KeyDown({param($s,$e) if($e.KeyCode -eq 'F7'){$script:enabled=-not $script:enabled;if(-not $script:enabled){Drag $false};RefreshStatus;$e.Handled=$true}elseif($e.KeyCode -eq 'F6'){[Windows.Forms.MessageBox]::Show("Arrow keys: move pointer`nShift + arrows: faster`nEnter/Space: left click`nBackspace: right click`nNumpad 0: hold click`nNumpad Decimal: release`nF7: toggle","Keyboard controls")|Out-Null;$e.Handled=$true}})
$timer=New-Object Windows.Forms.Timer;$timer.Interval=16;$timer.Add_Tick({if(-not $script:enabled){return};$p=New-Object MKCNative+POINT;[void][MKCNative]::GetCursorPos([ref]$p);$step=if(Down 0x10){40}else{16};$m=$false;if(Down 0x25){$p.X-=$step;$m=$true};if(Down 0x27){$p.X+=$step;$m=$true};if(Down 0x26){$p.Y-=$step;$m=$true};if(Down 0x28){$p.Y+=$step;$m=$true};if($m){$b=[Windows.Forms.Screen]::PrimaryScreen.Bounds;$p.X=[Math]::Max($b.Left,[Math]::Min($b.Right-1,$p.X));$p.Y=[Math]::Max($b.Top,[Math]::Min($b.Bottom-1,$p.Y));[void][MKCNative]::SetCursorPos($p.X,$p.Y)};$map=@{13='enter';32='space';8='back';96='drag';110='release'};foreach($k in $map.Keys){$d=Down ([int]$k);$old=$script:prev[[string]$k];if($null -eq $old){$old=$false};if($d -and -not $old){switch($map[$k]){'enter'{LClick}'space'{LClick}'back'{RClick}'drag'{Drag $true}'release'{Drag $false}}};$script:prev[[string]$k]=$d};if($script:proc){try{if($script:proc.HasExited){RefreshStatus}}catch{}}})
$form.Add_FormClosing({Drag $false;$timer.Stop()});$timer.Start();RefreshStatus;[void]$form.ShowDialog()
