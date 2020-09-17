$key = New-Item "HKLM:\SOFTWARE\JavaSoft\Java Runtime Environment" -Force
New-ItemProperty -Path $key.PSPath -PropertyType STRING -Name CurrentVersion -Value "1.8"

Start-Process -FilePath ".\FreeMind-Windows-Installer-1.0.1-min.exe" -ArgumentList "/VERYSILENT" -Wait

remove-item $key.PSPath -force -confirm:$False