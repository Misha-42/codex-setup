Set sh = CreateObject("WScript.Shell")
home = sh.ExpandEnvironmentStrings("%USERPROFILE%")
pwsh = home & "\AppData\Local\Microsoft\PowerShell\7\pwsh.exe"
If Not CreateObject("Scripting.FileSystemObject").FileExists(pwsh) Then pwsh = "C:\Program Files\PowerShell\7\pwsh.exe"
cmd = "wt -w 0 nt -d """ & home & """ --title ""Codex - Claude Sonnet"" """ & pwsh & """ -NoExit -Command ""codex -c model_provider=tooken --model claude-sonnet-5"""
sh.Run cmd, 0, False
