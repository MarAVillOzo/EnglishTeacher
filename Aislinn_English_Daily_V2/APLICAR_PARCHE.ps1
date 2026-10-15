$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework

$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$targetRoot=$here
if(-not (Test-Path -LiteralPath (Join-Path $targetRoot 'app\AislinnEnglish.ps1'))){
    $parent=Split-Path -Parent $here
    if(Test-Path -LiteralPath (Join-Path $parent 'app\AislinnEnglish.ps1')){$targetRoot=$parent}
}
$target=Join-Path $targetRoot 'app\AislinnEnglish.ps1'
$replacement=Join-Path $here 'patch\AislinnEnglish.ps1'
if(-not (Test-Path -LiteralPath $target)){
    [System.Windows.MessageBox]::Show(
        "No encontre app\AislinnEnglish.ps1.`n`nExtrae este parche DENTRO de la carpeta raiz de Aislinn English Daily V2.0 y ejecuta de nuevo APLICAR_PARCHE.cmd.",
        'Aislinn V2.0.1 patch','OK','Error')|Out-Null
    exit 2
}
if(-not (Test-Path -LiteralPath $replacement)){throw 'The replacement AislinnEnglish.ps1 is missing from the patch.'}

# Parse replacement with the real Windows PowerShell parser before touching the app.
$tokens=$null;$errors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile($replacement,[ref]$tokens,[ref]$errors)
if($errors -and $errors.Count -gt 0){
    $msg=($errors|ForEach-Object{"linea $($_.Extent.StartLineNumber), columna $($_.Extent.StartColumnNumber): $($_.Message)"}) -join "`n"
    [System.Windows.MessageBox]::Show("El parche NO se aplico porque Windows detecto un error de sintaxis:`n`n$msg",'Aislinn V2.0.1 patch','OK','Error')|Out-Null
    exit 3
}

$backup=$target+'.before_v2_0_1.bak'
if(-not (Test-Path -LiteralPath $backup)){Copy-Item -LiteralPath $target -Destination $backup -Force}
Copy-Item -LiteralPath $replacement -Destination $target -Force

# Parse the installed copy too.
$tokens2=$null;$errors2=$null
[void][System.Management.Automation.Language.Parser]::ParseFile($target,[ref]$tokens2,[ref]$errors2)
if($errors2 -and $errors2.Count -gt 0){
    Copy-Item -LiteralPath $backup -Destination $target -Force
    throw 'The patched file failed the final parser check. The original file was restored automatically.'
}

Set-Content -LiteralPath (Join-Path $targetRoot 'PATCH_VERSION.txt') -Encoding UTF8 -Value @(
    'Aislinn English Daily V2.0.1 Mic Bridge Patch',
    'Applied: '+(Get-Date -Format s),
    'Changes: deterministic Whisper-to-UI bridge; persistent transcript; no Windows audio changes.'
)

[System.Windows.MessageBox]::Show(
    "Parche V2.0.1 aplicado correctamente.`n`nNo se modifico Windows, Ollama, Qwen, drivers, dispositivos de audio ni el motor Whisper que ya funciona.`n`nAbre 1_EJECUTAR_PORTABLE.cmd y confirma que arriba diga V2.0.1.",
    'Aislinn V2.0.1 patch','OK','Information')|Out-Null
