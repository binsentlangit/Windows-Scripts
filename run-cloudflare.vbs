Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -ExecutionPolicy Bypass -File ""C:\Scripts\manage-cloudflare.ps1"" -Verb RunAs", 0, True
