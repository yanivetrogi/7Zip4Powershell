#Install-Module -Name 7Zip4Powershell

[bool]$user_interactive = [Environment]::UserInteractive;
[bool]$delete_file = $false;

# Path to the files we compress
[string]$files_to_process_path = 'C:\Backup';

 #region <Logging>
[string]$log4net_log = Join-Path $PSScriptRoot '7Zip4Powershell.log';
[string]$log4net_dll = Join-Path $PSScriptRoot 'log4net.dll';

[void][Reflection.Assembly]::LoadFile($log4net_dll);
[log4net.LogManager]::ResetConfiguration();

$FileAppender = new-object log4net.Appender.FileAppender(([log4net.Layout.ILayout](new-object log4net.Layout.PatternLayout('%date{yyyy-MM-dd HH:mm:ss.fff}  %level  %message%n')), $log4net_log, $True));
$FileAppender.Threshold = [log4net.Core.Level]::All;
[log4net.Config.BasicConfigurator]::Configure($FileAppender);

$Log=[log4net.LogManager]::GetLogger("root");
#endregion

<#
# Create a folder for the compressed files to be generated
[string]$files_processed_path = Join-Path $files_to_process_path 'processed_files';
if(-not (Test-Path $files_processed_path)) { mkdir $files_processed_path | Out-Null; }
#>


$sw = [System.Diagnostics.Stopwatch]::StartNew(); 
$files = Get-ChildItem $files_to_process_path -Recurse -include ('*.bak') | Where-Object {$_.PSIsContainer -eq $False;} 
foreach($file in $files)
{
    if ($user_interactive -eq $true) {Write-Host -ForegroundColor Green $file};    
    try
    {           
        $sw.Start();
        $Log.Info($file.FullName + ' Starting...')           

        # Compress
        $destination_file =  $file.FullName + '.zip'; 
        Compress-7Zip -Format SevenZip -CompressionLevel Low -Path $file.FullName -ArchiveFileName $destination_file -Password $Credentials.Password;
        $sw.Stop();
        
        if ($user_interactive -eq $true) {Write-Host -ForegroundColor Yellow $file.FullName ' | Elapsed TotalSeconds: ' $sw.Elapsed.TotalSeconds ' | Elapsed TotalMinutes: ' $sw.Elapsed.TotalMinutes};   
        $Log.Info($file.FullName + ': Complted. | size: ' + $file.Length + 'Elapsed TotalSeconds: ' + $sw.Elapsed.TotalSeconds + ' | Elapsed TotalMinutes: ' + $sw.Elapsed.TotalMinutes);
        $sw.Reset();

        
        
        


        # Expand
        # Expand-7Zip -ArchiveFileName $destination_file -TargetPath $files_processed_path -Password $Credentials.Password;

        # Delete teh file we zipped
        if($delete_file -eq $true) {$file.Delete();}
    }
    catch [Exception] 
    {
        $exception = $_.Exception;
        $Log.Error($file.Name + ':  ' + $exception)

        if ($user_interactive -eq $true) {Write-Host -ForegroundColor Red $exception}      
        if ($user_interactive -eq $false) {Throw; }        
    }
}