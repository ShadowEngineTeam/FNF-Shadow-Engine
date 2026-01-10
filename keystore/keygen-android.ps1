$ErrorActionPreference = "Stop"

function Read-Password($Prompt) {
    Write-Host $Prompt
    $secure = Read-Host -AsSecureString
    return [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    )
}

$alias = Read-Host "Key alias name [unknown]"
if ([string]::IsNullOrWhiteSpace($alias)) {
    $alias = "unknown"
}

while ($true) {
    $storePass = Read-Password "Keystore password:"
    $confirm   = Read-Password "Confirm keystore password:"

    if ([string]::IsNullOrEmpty($storePass)) {
        Write-Host "Password cannot be empty."
        continue
    }

    if ($storePass.Length -lt 6) {
        Write-Host "Password must be at least 6 characters long."
        continue
    }

    if ($storePass -ne $confirm) {
        Write-Host "Passwords do not match."
        continue
    }

    break
}

function Prompt-Default($Prompt, $Default) {
    $value = Read-Host "$Prompt [$Default]"
    if ([string]::IsNullOrWhiteSpace($value)) { $Default } else { $value }
}

$CN = Prompt-Default "Your full name (CN)" "Unknown"
$OU = Prompt-Default "Organizational unit (OU)" "Unknown"
$O  = Prompt-Default "Organization (O)" "Unknown"
$L  = Prompt-Default "City or locality (L)" "Unknown"
$ST = Prompt-Default "State or province (ST)" "Unknown"
$C  = Prompt-Default "Country code (2 letters)" "US"

Write-Host "Generating keystore..."

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$KeystorePath = Join-Path $ScriptDir "android\key.keystore"
$OutputJson   = Join-Path $ScriptDir "android\keystore.json"

keytool -genkeypair `
  -keystore "$KeystorePath" `
  -alias "$alias" `
  -keyalg RSA `
  -keysize 4096 `
  -validity 365 `
  -storepass "$storePass" `
  -keypass "$storePass" `
  -dname "CN=$CN, OU=$OU, O=$O, L=$L, ST=$ST, C=$C" `
  -v

@"
{
  "alias": "$alias",
  "storepass": "$storePass",
  "keypass": "$storePass"
}
"@ | Set-Content -Encoding UTF8 $OutputJson

Write-Host "Keystore generated at: $KeystorePath"
Write-Host "Keystore info saved at: $OutputJson"
