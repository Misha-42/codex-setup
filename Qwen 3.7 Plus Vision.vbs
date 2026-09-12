Set sh = CreateObject("WScript.Shell")
home = sh.ExpandEnvironmentStrings("%USERPROFILE%")
pwsh = home & "\AppData\Local\Microsoft\PowerShell\7\pwsh.exe"
If Not CreateObject("Scripting.FileSystemObject").FileExists(pwsh) Then pwsh = "C:\Program Files\PowerShell\7\pwsh.exe"
cmd = "wt -w 0 nt -d """ & home & """ --title ""Claude - Qwen 3.7 Plus Vision"" """ & pwsh & """ -NoExit -Command ""claude --model qwen3.7-plus"""
sh.Run cmd, 0, False
