' todo.vbs - PowerShellスクリプトをコンソール非表示で起動するランチャー
' このファイルと todo.ps1 を同じフォルダに置いてダブルクリック
' （スタートアップに置いておけばPC起動時に自動で常駐）

Set fso = CreateObject("Scripting.FileSystemObject")
folder  = fso.GetParentFolderName(WScript.ScriptFullName)
ps1Path = folder & "\todo.ps1"

Set sh = CreateObject("WScript.Shell")
sh.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & ps1Path & """", 0, False
