# ============================================================
# Simple Checkbox ToDo (Insert key to toggle show/hide)
#
# Save file: %USERPROFILE%\todo.txt
# Format: "[x] done item" / "[ ] pending item"
# Exit: Right-click tray icon -> Exit
# Change key: edit $VK_TOGGLE_KEY below
#   0x2D = Insert (default)
#   0x91 = ScrollLock
#   0x13 = Pause/Break
#   0x70..0x7B = F1..F12
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$VK_TOGGLE_KEY = 0x2D   # Insert

# --- Win32 API ---
$apiSig = @'
[DllImport("user32.dll")]
public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);
[DllImport("user32.dll")]
public static extern bool UnregisterHotKey(IntPtr hWnd, int id);
'@
$User32 = Add-Type -MemberDefinition $apiSig -Name User32 -Namespace TodoApp -PassThru

# --- WM_HOTKEY filter ---
$filterSrc = @'
using System;
using System.Windows.Forms;
public class HotKeyFilter : IMessageFilter {
    public const int WM_HOTKEY = 0x0312;
    public event EventHandler Pressed;
    public bool PreFilterMessage(ref Message m) {
        if (m.Msg == WM_HOTKEY && Pressed != null) {
            Pressed(this, EventArgs.Empty);
            return true;
        }
        return false;
    }
}
'@
Add-Type -TypeDefinition $filterSrc -ReferencedAssemblies System.Windows.Forms

# --- ToDo file ---
$todoFile = Join-Path $env:USERPROFILE 'todo.txt'
if (-not (Test-Path $todoFile)) { '' | Set-Content $todoFile -Encoding UTF8 }

# --- Form ---
$form = New-Object System.Windows.Forms.Form
$form.Text = 'ToDo'
$form.Size = New-Object System.Drawing.Size(420, 520)
$form.TopMost = $true
$form.ShowInTaskbar = $false
$form.StartPosition = 'Manual'
$form.Location = New-Object System.Drawing.Point(100, 100)

# Input box (top)
$inputBox = New-Object System.Windows.Forms.TextBox
$inputBox.Dock = 'Top'
$inputBox.Font = New-Object System.Drawing.Font('Yu Gothic UI', 12)

# Remove-checked button (bottom)
$cleanBtn = New-Object System.Windows.Forms.Button
$cleanBtn.Text = 'Remove checked items'
$cleanBtn.Dock = 'Bottom'
$cleanBtn.Height = 32

# Checked list (fill)
$list = New-Object System.Windows.Forms.CheckedListBox
$list.Dock = 'Fill'
$list.CheckOnClick = $true
$list.Font = New-Object System.Drawing.Font('Yu Gothic UI', 12)
$list.IntegralHeight = $false

# Order matters: Fill first, then Bottom, then Top
$form.Controls.Add($list)
$form.Controls.Add($cleanBtn)
$form.Controls.Add($inputBox)

# --- Save / Load ---
function Save-Todo {
    $lines = @()
    for ($i = 0; $i -lt $list.Items.Count; $i++) {
        $mark = if ($list.GetItemChecked($i)) { '[x]' } else { '[ ]' }
        $lines += "$mark $($list.Items[$i])"
    }
    Set-Content -Path $todoFile -Value $lines -Encoding UTF8
}

function Load-Todo {
    $list.Items.Clear()
    if (Test-Path $todoFile) {
        Get-Content $todoFile -Encoding UTF8 | ForEach-Object {
            if ($_ -match '^\[(x| )\]\s?(.*)$') {
                $checked = $matches[1] -eq 'x'
                [void]$list.Items.Add($matches[2], $checked)
            } elseif ($_.Trim()) {
                [void]$list.Items.Add($_, $false)
            }
        }
    }
}
Load-Todo

# --- Add item on Enter ---
$inputBox.Add_KeyDown({
    param($s, $e)
    if ($e.KeyCode -eq 'Enter') {
        $e.SuppressKeyPress = $true
        $text = $inputBox.Text.Trim()
        if ($text) {
            [void]$list.Items.Add($text, $false)
            $inputBox.Clear()
            Save-Todo
        }
    }
})

# --- Delete selected item on Delete key ---
$list.Add_KeyDown({
    param($s, $e)
    if ($e.KeyCode -eq 'Delete' -and $list.SelectedIndex -ge 0) {
        $list.Items.RemoveAt($list.SelectedIndex)
        Save-Todo
    }
})

# --- Save when check state changes (deferred, since ItemCheck fires before state updates) ---
$list.Add_ItemCheck({
    $form.BeginInvoke([Action]{ Save-Todo }) | Out-Null
})

# --- Remove checked items ---
$cleanBtn.Add_Click({
    for ($i = $list.Items.Count - 1; $i -ge 0; $i--) {
        if ($list.GetItemChecked($i)) {
            $list.Items.RemoveAt($i)
        }
    }
    Save-Todo
})

# --- X button -> hide instead of close ---
$form.Add_FormClosing({
    param($s, $e)
    if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing) {
        $e.Cancel = $true
        $form.Hide()
    }
})

# --- Create handle without showing ---
$null = $form.Handle

# --- Register hotkey ---
$HOTKEY_ID = 1
[void]$User32::RegisterHotKey($form.Handle, $HOTKEY_ID, 0, $VK_TOGGLE_KEY)

# --- Toggle ---
$toggle = {
    if ($form.Visible) {
        $form.Hide()
    } else {
        $form.Show()
        $form.Activate()
        $inputBox.Focus() | Out-Null
    }
}
$filter = New-Object HotKeyFilter
$filter.add_Pressed($toggle)
[System.Windows.Forms.Application]::AddMessageFilter($filter)

# --- Tray icon ---
$tray = New-Object System.Windows.Forms.NotifyIcon
$tray.Icon = [System.Drawing.SystemIcons]::Information
$tray.Text = 'ToDo (Insert to toggle)'
$tray.Visible = $true

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$itemShow = $menu.Items.Add('Show / Hide')
$itemShow.add_Click($toggle)
$itemExit = $menu.Items.Add('Exit')
$itemExit.add_Click({
    [void]$User32::UnregisterHotKey($form.Handle, $HOTKEY_ID)
    $tray.Visible = $false
    $tray.Dispose()
    [System.Windows.Forms.Application]::ExitThread()
})
$tray.ContextMenuStrip = $menu
$tray.add_MouseDoubleClick($toggle)

# --- Run message loop (hidden initially) ---
$ctx = New-Object System.Windows.Forms.ApplicationContext
[System.Windows.Forms.Application]::Run($ctx)