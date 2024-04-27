set "dossier=.\release\gba-wav-to-s3m-converter-1.0.0"

if exist %dossier%.zip del %dossier%.zip


if exist "%dossier%" (
    echo Le dossier existe déjà. Nettoyage en cours...
    del /q "%dossier%\*" >nul 2>&1
    for /d %%i in ("%dossier%\*") do rd /s /q "%%i" >nul 2>&1
) else (
    echo Le dossier n'existe pas. Création du dossier...
    mkdir "%dossier%"
)

dart compile exe .\bin\core\main.dart -o %dossier%\gba-wav-to-s3m-converter.exe
copy .\README.md %dossier%\README.md
copy .\LICENSE %dossier%\LICENSE
robocopy .\sox-14-4-2 %dossier%\sox-14-4-2 /mir
robocopy .\examples %dossier%\examples /mir
mkdir %dossier%\temp

PowerShell Compress-Archive -Path %dossier% -DestinationPath %dossier%.zip

pause
