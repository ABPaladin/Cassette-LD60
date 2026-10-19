$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Speech
$taskSpeechData = Get-Content -LiteralPath '.rebuild_backup/speech-input.json' -Raw | ConvertFrom-Json
$taskSpeech = New-Object System.Speech.Synthesis.SpeechSynthesizer
try {
    $taskSpeech.SelectVoice('Microsoft Zira Desktop')
    $taskSpeech.Rate = -1
    $taskSpeech.Volume = 90
    foreach ($entry in $taskSpeechData) {
        $taskOutput = Join-Path (Get-Location) $entry.path
        $taskSpeech.SetOutputToWaveFile($taskOutput)
        $taskSpeech.Speak([string]$entry.text)
        $taskSpeech.SetOutputToNull()
    }
} finally { $taskSpeech.Dispose() }
