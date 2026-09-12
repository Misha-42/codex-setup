Set sh = CreateObject("WScript.Shell")
home = sh.ExpandEnvironmentStrings("%USERPROFILE%")
pwsh = home & "\AppData\Local\Microsoft\PowerShell\7\pwsh.exe"
If Not CreateObject("Scripting.FileSystemObject").FileExists(pwsh) Then pwsh = "C:\Program Files\PowerShell\7\pwsh.exe"
cmd = "wt -w 0 nt -d """ & home & """ --title ""Claude - GLM 5.2 Fast Preview"" """ & pwsh & """ -NoExit -Command ""claude --model glm-5.2-fast-preview"""
sh.Run cmd, 0, False
