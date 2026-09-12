Set sh = CreateObject("WScript.Shell")
home = sh.ExpandEnvironmentStrings("%USERPROFILE%")
pwsh = home & "\AppData\Local\Microsoft\PowerShell\7\pwsh.exe"
If Not CreateObject("Scripting.FileSystemObject").FileExists(pwsh) Then pwsh = "C:\Program Files\PowerShell\7\pwsh.exe"
cmd = "wt -w 0 nt -d """ & home & """ --title ""Claude - DeepSeek V4.1 Flash (OpenCode Go)"" """ & pwsh & """ -NoExit -ExecutionPolicy Bypass -File """ & home & "\.claude-go\launch-go.ps1"""
sh.Run cmd, 0, False
