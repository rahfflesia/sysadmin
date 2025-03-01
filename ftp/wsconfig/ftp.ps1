Install-WindowsFeature Web-Server -IncludeManagementTools
Install-WindowsFeature Web-Ftp-Server -IncludeAllSubFeature
Install-WindowsFeature Web-Basic-Auth

mkdir "C:\FTP"

New-WebFtpSite -Name "FTP" -Port 21 -PhysicalPath "C:\FTP\" -Force

# Creación del grupo
$FTPUserGroupName = "MiembrosFTP"
$ADSI = [ADSI]"WinNT://$env:ComputerName"
$FTPUserGroup = $ADSI.Create("Group", "$FTPUserGroupName")
$FTPUserGroup.SetInfo()
$FTPUserGroup.Description = "Usuarios FTP"
$FTPUserGroup.SetInfo()

# Creación del usuario
$FTPUserName = "Quintana"
$FTPPassword = "#contrasena11"
$CreateUserFTPUser = $ADSI.Create("User", "$FTPUserName")
$CreateUserFTPUser.SetInfo()
$CreateUserFTPUser.SetPassword("$FTPPassword")
$CreateUserFTPUser.SetInfo()

# Unión de los usuarios al grupo FTP
$UserAccount = New-Object System.Security.Principal.NTAccount("$FTPUserName")
$SID = $UserAccount.Translate([System.Security.Principal.SecurityIdentifier])
$Group = [ADSI]"WinNT://$env:ComputerName/$FTPUserGroupName,Group"
$User = [ADSI]"WinNT://$SID"
$Group.Add($User.Path)

# Habilitar autenticacion básica
Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.Security.authentication.basicAuthentication.enabled -Value $true

# Permisos de lectura y escritura
Add-WebConfiguration "/system.ftpServer/security/authorization" -value @{acessType="Allow";roles="$FTPUserGroupName";permissions=3} -PSPath IIS:\ -location "FTP"

Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.controlChannelPolicy -Value 0
Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.dataChannelPolicy -Value 0

Restart-WebItem "IIS:\Sites\FTP"