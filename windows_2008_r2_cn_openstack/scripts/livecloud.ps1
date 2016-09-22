Write-Host "Delete livecloud User"
$UserExist = [ADSI]::Exists("WinNT://livecloud-2008/livecloud")
if ($UserExist) {
    [ADSI]$server="WinNT://livecloud-2008"
    $server.delete("user", "livecloud")
}

function xzFile($src, $dest) {
    $sevenZip = "C:\Windows\System32\7za.exe"
    & cmd "/c $sevenZip x `"$src`" -so | $sevenZip x -aoa -si -ttar -o`"$dest`""
}

function download($url, $dest) {
    Write-Host "Downloading $url"
    ( New-Object System.Net.WebClient).DownloadFile( $url, $dest)
}

$url = "http://192.166.69.12/Softwares/OS/"
$bin_dir = "C:\Windows\System32\"
$tmp_dir = "C:\Windows\Temp\"

download $url"tools/7za.exe" $bin_dir"7za.exe"
download $url"tools/curl.exe" $bin_dir"curl.exe"
download $url"tools/virtiodriver2k8_openstack.tar.gz" $tmp_dir"virtiodriver.tar.gz"
download $url"tools/virtio/guest-agent/qemu-ga-x64.msi" $tmp_dir"qemu-ga-x86_64.msi"
download $url"tools/CloudbaseInitSetup_x64.msi" $tmp_dir"cloudbase.msi"

if (!(Test-Path "C:\Windows\virtiodriver" )) {
    Write-Host "Install VirtIO Driver...."
    xzFile "C:\Windows\Temp\virtiodriver.tar.gz" "C:\Windows"
    $Host.UI.RawUI.WindowTitle = "Installing VirtIO certificate..."
    $virtioCertPath = "C:\Windows\virtiodriver\VirtIO.cer"
    $virtioDriversPath = "C:\Windows\virtiodriver"
    $cacert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($virtioCertPath)
    $castore = New-Object System.Security.Cryptography.X509Certificates.X509Store([System.Security.Cryptography.X509Certificates.StoreName]::TrustedPublisher,`
           [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine)
    $castore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    $castore.Add($cacert)
    Write-Host "Installing VirtIO drivers from: $virtioDriversPath"
    $process = Start-process -Wait -PassThru pnputil "-i -a C:\Windows\virtiodriver\*.inf"
    if ($process.ExitCode -eq 0){
        Write-Host "VirtIO has been successfully installed"
    } else {
        Write-Host "InstallVirtIO failed"
    }
}

if (!(Test-Path "C:\Program Files\qemu-ga" )) {
    $msiFile = "C:\Windows\Temp\qemu-ga-x86_64.msi"
    $targetdit = "C:\Program Files\qemu-ga"
    $arguments = @(
        "/i"
        "`"$msiFile`""
        "/qn"
		"/l*v C:\Windows\Temp\qemu-ga-setup.log"
        "/norestart"
        "ALLUSERS=1"
        "TARGETDIR=`"$targetdit`""
    )
    Write-Host "Installing $msiFile....."
    $process = Start-Process -FilePath msiexec.exe -ArgumentList $arguments -Wait -PassThru
    if ($process.ExitCode -eq 0){
        Write-Host "$msiFile has been successfully installed"
        Start-Service "QEMU Guest Agent VSS Provider"
        Start-Service "QEMU-GA"
    } else {
        Write-Host "installer exit code $($process.ExitCode) for file $($msifile)"
    }   
}

if (!(Test-Path "C:\Program Files\Cloudbase Solutions\Cloudbase-Init" )) {
    $msiFile = "C:\Windows\Temp\cloudbase.msi"
    $targetdit = "C:\Program Files\Cloudbase Solutions\Cloudbase-Init"
    $arguments = @(
        "/i"
        "`"$msiFile`""
        "/qn"
        "/norestart"
		"/l*v C:\Windows\Temp\CloudbaseInitSetup.log"
        "ALLUSERS=1"
		"LOGGINGSERIALPORTNAME=COM1"
        "TARGETDIR=`"$targetdit`""
    )
    Write-Host "Installing $msiFile....."
    $process = Start-Process -FilePath msiexec.exe -ArgumentList $arguments -Wait -PassThru
    if ($process.ExitCode -eq 0){
        Write-Host "$msiFile has been successfully installed"
        Start-Service "cloudbase-init"
    } else {
        Write-Host "installer exit code $($process.ExitCode) for file $($msifile)"
    }   
}

if (Test-Path "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\Unattend.xml") {
    Write-Host "run sysprep to generalize the system (and shutdown)"
    Start-Process "C:\Windows\System32\Sysprep\Sysprep.exe" "/quiet /generalize /oobe /quit /unattend:'C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\Unattend.xml'" -NoNewWindow -Wait
}

