param(
    [Parameter(Mandatory=$true)][string]$Root,
    [Parameter(Mandatory=$true)][string]$OutputFile,
    [Parameter(Mandatory=$true)][string]$CancelFile,
    [int]$TimeoutSeconds=14
)
$ErrorActionPreference='Stop'

function Write-Result([string]$Status,[string]$Text,[string]$Message,[double]$Confidence){
    $o=[pscustomobject]@{status=$Status;text=$Text;message=$Message;confidence=$Confidence}
    $o|ConvertTo-Json -Depth 4 -Compress|Set-Content -LiteralPath $OutputFile -Encoding UTF8
}
function Clean-Line([string]$Line){
    if($null -eq $Line){return ''}
    $x=[regex]::Replace($Line,'\x1B\[[0-9;?]*[ -/]*[@-~]','')
    return $x.Trim()
}

$proc=$null
try{
    $runtimeDir=Join-Path $Root 'runtime\whisper'
    $modelPath=Join-Path $Root 'models\ggml-tiny.en-q5_1.bin'
    if(-not (Test-Path -LiteralPath $runtimeDir) -or -not (Test-Path -LiteralPath $modelPath)){
        Write-Result 'not_prepared' '' 'Private local speech engine is not prepared.' 0.0
        exit 2
    }
    $stream=Get-ChildItem -LiteralPath $runtimeDir -Filter 'whisper-stream.exe' -File -Recurse -ErrorAction SilentlyContinue|Select-Object -First 1
    if(-not $stream){Write-Result 'not_prepared' '' 'whisper-stream.exe is missing.' 0.0;exit 2}

    $threads=[Math]::Max(1,[Math]::Min(4,[Environment]::ProcessorCount-1))
    $psi=New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName=$stream.FullName
    $psi.WorkingDirectory=$stream.Directory.FullName
    $psi.UseShellExecute=$false
    $psi.CreateNoWindow=$true
    $psi.RedirectStandardOutput=$true
    $psi.RedirectStandardError=$true
    $psi.Arguments='-m "'+$modelPath+'" -l en -t '+$threads+' --step 0 --length 8000 --keep 200 -vth 0.55 -fth 100'
    $proc=New-Object System.Diagnostics.Process
    $proc.StartInfo=$psi
    if(-not $proc.Start()){throw 'whisper-stream.exe could not start.'}

    $deadline=(Get-Date).AddSeconds([Math]::Max(6,$TimeoutSeconds))
    $cancelled=$false
    while(-not $proc.HasExited -and (Get-Date) -lt $deadline){
        if(Test-Path -LiteralPath $CancelFile){$cancelled=$true;break}
        Start-Sleep -Milliseconds 120
    }
    if(-not $proc.HasExited){
        try{$proc.Kill()}catch{}
        try{$proc.WaitForExit(2500)|Out-Null}catch{}
    }
    $stdout='';$stderr=''
    try{$stdout=$proc.StandardOutput.ReadToEnd()}catch{}
    try{$stderr=$proc.StandardError.ReadToEnd()}catch{}
    if($cancelled){Write-Result 'cancelled' '' 'Listening was stopped by the user.' 0.0;exit 0}

    $combined=($stdout+"`n"+$stderr)
    $combined=[regex]::Replace($combined,'\x1B\[[0-9;?]*[ -/]*[@-~]','')
    $parts=New-Object System.Collections.Generic.List[string]
    $rx='(?m)^\[[0-9:.]+\s*-->\s*[0-9:.]+\]\s+(.+?)\s*$'
    foreach($m in [regex]::Matches($combined,$rx)){
        $t=(Clean-Line $m.Groups[1].Value)
        if(-not [string]::IsNullOrWhiteSpace($t) -and $t -notmatch '^\['){
            if($parts.Count -eq 0 -or $parts[$parts.Count-1] -ne $t){[void]$parts.Add($t)}
        }
    }
    if($parts.Count -eq 0){
        foreach($line in ($combined -split "`r?`n")){
            $t=Clean-Line $line
            if([string]::IsNullOrWhiteSpace($t)){continue}
            if($t -match '^(whisper_|ggml_|main:|system_info:|audio_|capture|init:|processing|###|\[Start speaking\]|\[BLANK_AUDIO\])'){continue}
            if($t -match '^\[[0-9:.]+\s*-->'){continue}
            if($t.Length -ge 2 -and $t.Length -le 300){
                if($parts.Count -eq 0 -or $parts[$parts.Count-1] -ne $t){[void]$parts.Add($t)}
            }
        }
    }
    $text=($parts -join ' ').Trim()
    $text=[regex]::Replace($text,'\s+',' ')
    if(-not [string]::IsNullOrWhiteSpace($text)){
        Write-Result 'success' $text 'Recognized privately with whisper.cpp.' 0.90
        exit 0
    }

    $low=$combined.ToLowerInvariant()
    if($low -match 'capture device' -and ($low -match 'failed|error|not found|cannot|could not')){
        Write-Result 'device_error' '' 'The local engine could not open the default microphone. Check that Windows still sees an input device and that another app is not holding it exclusively.' 0.0
        exit 3
    }
    Write-Result 'no_result' '' 'No complete English sentence was detected. Speak one sentence and then pause for a moment.' 0.0
    exit 4
}catch{
    try{if($proc -and -not $proc.HasExited){$proc.Kill()}}catch{}
    try{Write-Result 'error' '' $_.Exception.Message 0.0}catch{}
    exit 1
}
