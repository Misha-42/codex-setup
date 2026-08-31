Set objShell = CreateObject("WScript.Shell")
objShell.Run "pwsh.exe -ExecutionPolicy Bypass -File ""C:\Users\user\codex-smart.ps1""", 1, False
