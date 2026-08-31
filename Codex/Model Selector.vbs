Set objShell = CreateObject("WScript.Shell")
objShell.Run "pwsh.exe -ExecutionPolicy Bypass -File ""C:\Users\user\model-selector.ps1 -Interactive""", 1, False
