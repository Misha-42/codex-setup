Set sh = CreateObject("WScript.Shell")
home = sh.ExpandEnvironmentStrings("%USERPROFILE%")
pwsh = home & "\AppData\Local\Microsoft\PowerShell\7\pwsh.exe"
If Not CreateObject("Scripting.FileSystemObject").FileExists(pwsh) Then pwsh = "C:\Program Files\PowerShell\7\pwsh.exe"
cmd = "wt -w 0 nt -d """ & home & """ --title ""Claude - Qwen 3 Coder 480B (TOP) · NO CACHE"" """ & pwsh & """ -NoExit -Command ""claude --model qwen3-coder-480b-a35b-instruct"""
sh.Run cmd, 0, False
