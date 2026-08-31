CreateObject("WScript.Shell").Run "wt -w 0 nt -d ""C:\Users\user"" --title ""Codex - Custom Model"" ""C:\Program Files\PowerShell\7\pwsh.exe"" -NoExit -Command ""codex --model %MODEL%""", 0, False
