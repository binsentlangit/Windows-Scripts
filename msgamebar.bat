reg add HKCR\ms-gamebar /f /ve /d "URL:ms-gamebar"
reg add HKCR\ms-gamebar /f /v "URL Protocol" /d ""
reg add HKCR\ms-gamebar /f /v "NoOpenWith" /d ""
reg add HKCR\ms-gamebar\shell\open\command /f /ve /d "\"%SystemRoot%\System32\systray.exe\""

reg add HKCR\ms-gamebarservices /f /ve /d "URL:ms-gamebarservices"
reg add HKCR\ms-gamebarservices /f /v "URL Protocol" /d ""
reg add HKCR\ms-gamebarservices /f /v "NoOpenWith" /d ""
reg add HKCR\ms-gamebarservices\shell\open\command /f /ve /d "\"%SystemRoot%\System32\systray.exe\""
