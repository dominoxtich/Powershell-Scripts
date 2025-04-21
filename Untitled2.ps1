# Zakres czasowy - ostatnie 7 dni (pełne 168 godzin)
$startDate = (Get-Date).AddDays(-7)
$endDate = (Get-Date)

# Lista użytkowników systemowych do pominięcia
$systemUsers = @(
    'SYSTEM',
    'LOCAL SERVICE',
    'NETWORK SERVICE',
    'UMFD-0', 'UMFD-1'
)

# Pobierz zdarzenia logowania/wylogowania/blokady, uruchomienia i wyłączenia systemu
$logonEvents = Get-WinEvent -FilterHashtable @{
    LogName = 'Security';
    ID = 4624, 4634, 4800, 4801, 6005, 6006;
    StartTime = $startDate;
    EndTime = $endDate
} -ErrorAction SilentlyContinue

# Sprawdzenie, czy są zdarzenia w logach
if ($logonEvents.Count -eq 0) {
    Write-Host "Brak zdarzeń w logach w okresie od $startDate do $endDate." -ForegroundColor Red
    return
}

# Przetwórz i filtruj tylko logowania, wylogowania, blokady/odblokowania, uruchomienia i wyłączenia
$processed = $logonEvents | ForEach-Object {
    $xml = [xml]$_.ToXml()
    $time = $_.TimeCreated

    $user = $xml.Event.EventData.Data | Where-Object { $_.Name -eq "TargetUserName" -or $_.Name -eq "SubjectUserName" } | Select-Object -ExpandProperty '#text'
    $logonType = $xml.Event.EventData.Data | Where-Object { $_.Name -eq "LogonType" } | Select-Object -ExpandProperty '#text'

    # Odfiltruj konta systemowe i sprawdź typ logowania
    if (![string]::IsNullOrWhiteSpace($user) -and
        $user -notin $systemUsers -and
        $user -notmatch '^DWM-\d+$' -and
        ($_.Id -ne 4624 -or ($logonType -eq '2' -or $logonType -eq '10'))) {

        $action = switch ($_.Id) {
            4624 { "Logowanie" }
            4634 { "Wylogowanie" }
            4800 { "Blokada" }
            4801 { "Odblokowanie" }
            6005 { "Uruchomienie systemu" }
            6006 { "Wyłączenie systemu" }
            default { "Inne" }
        }

        [PSCustomObject]@{
            Dzien      = $time.ToString("yyyy-MM-dd")
            Godzina    = $time.ToString("HH:mm:ss")
            Uzytkownik = $user
            Czynność   = $action
        }
    }
}

# Jeśli przetworzono jakieś dane, wyświetl je, w przeciwnym razie komunikat
if ($processed.Count -gt 0) {
    # Grupowanie po dniu i wypisywanie
    $processed | Sort-Object Dzien, Godzina | Group-Object Dzien | ForEach-Object {
        Write-Host "`n=== $($_.Name) ===" -ForegroundColor Cyan
        $_.Group | Format-Table @{Label="Godzina";Expression={$_.Godzina}},
                             @{Label="Użytkownik";Expression={$_.Uzytkownik}},
                             @{Label="Czynność";Expression={$_.Czynność}} -AutoSize
    }
} else {
    Write-Host "Brak danych do wyświetlenia" -ForegroundColor Red
}

# Eksport do CSV
#$exportPath = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "logowania.csv")
#$processed | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8

#Write-Host "`nDane zostały zapisane do pliku: $exportPath" -ForegroundColor Green
