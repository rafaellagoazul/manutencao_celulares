
<# Executa pytest, gera TXT único com cobertura e (opcional) JSON. #>

param(
  [string]$OutDir = "artifacts",
  [string]$CovTarget = "app",
  [switch]$Json
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
Set-Location $here

$venv = ".\.venv\Scripts\Activate.ps1"
if (!(Test-Path $venv)) { Write-Host "ERRO: venv não encontrada"; exit 1 }
& $venv
$env:PYTHONIOENCODING = "utf-8"

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$txtFile  = Join-Path $OutDir "tests_report.txt"
$jsonFile = Join-Path $OutDir "tests_report.json"
$junitXml = Join-Path $OutDir "junit.xml"
$covXml   = Join-Path $OutDir "coverage.xml"
Remove-Item $txtFile,$jsonFile,$junitXml,$covXml -Force -ErrorAction SilentlyContinue

python -m pip install --upgrade pip | Out-Null
if (Test-Path ".\requirements.txt") { pip install -r requirements.txt | Out-Null }
pip install pytest-cov | Out-Null
if ($Json) { pip install pytest-json-report | Out-Null }

$pytestArgs = @(
  "-q","-r","a","--disable-warnings","--maxfail=1",
  "--junitxml",$junitXml,
  "--cov=$CovTarget","--cov-branch",
  "--cov-report","term-missing:skip-covered",
  "--cov-report","xml:$covXml"
)
if ($Json) { $pytestArgs += @("--json-report","--json-report-file",$jsonFile) }

"== Test run started: $(Get-Date -Format s)" | Out-File $txtFile
"== Working dir: $(Get-Location)"            | Out-File $txtFile -Append
"== Python: $(python --version)"             | Out-File $txtFile -Append
"== Pytest: $(pytest --version)"             | Out-File $txtFile -Append
"== Coverage target: $CovTarget"             | Out-File $txtFile -Append
""                                           | Out-File $txtFile -Append

Write-Host "Executando pytest..." -ForegroundColor Cyan
$ErrorActionPreference = "Continue"
& pytest @pytestArgs 2>&1 | Tee-Object -FilePath $txtFile -Append
$exit = $LASTEXITCODE
$ErrorActionPreference = "Stop"

function Get-DoubleInvariant([string]$val) { if ([string]::IsNullOrWhiteSpace($val)) { return $null }; $styles=[System.Globalization.NumberStyles]::Float; $ci=[System.Globalization.CultureInfo]::InvariantCulture; $out=0.0; if ([System.Double]::TryParse($val,$styles,$ci,[ref]$out)) { return $out } ; return $null }
function Add-CoverageSummaryToTxt { param([string]$xmlPath,[string]$txtPath)
  "" | Out-File $txtPath -Append
  if (-not (Test-Path $xmlPath)) { "== Coverage summary: coverage.xml NÃO encontrado" | Out-File $txtPath -Append; return }
  try { [xml]$cov = Get-Content $xmlPath -Raw; $n=$cov.coverage; $lr=Get-DoubleInvariant ($n.'line-rate'); $br=Get-DoubleInvariant ($n.'branch-rate'); $lc=$n.'lines-covered'; $lv=$n.'lines-valid'; $pct=[Math]::Round((if($lr -ne $null){$lr}else{0})*100,2); $pctb= if($br -ne $null){[Math]::Round($br*100,2)} else {$null}; "== Coverage summary (from coverage.xml)" | Out-File $txtPath -Append; if ($lc -and $lv) { "Lines: $pct%  ($lc/$lv)" | Out-File $txtPath -Append } else { "Lines: $pct%" | Out-File $txtPath -Append }; if ($pctb -ne $null) { "Branches: $pctb%" | Out-File $txtPath -Append } } catch { "== Coverage summary: erro ao ler coverage.xml: $_" | Out-File $txtPath -Append } }
Add-CoverageSummaryToTxt -xmlPath $covXml -txtPath $txtFile
"== Exit code: $exit" | Out-File $txtFile -Append

if ($Json -and (Test-Path $jsonFile) -and (Test-Path $covXml)) {
  try { [xml]$cov = Get-Content $covXml -Raw; $n=$cov.coverage; $lr=Get-DoubleInvariant ($n.'line-rate'); $br=Get-DoubleInvariant ($n.'branch-rate'); $lc=$n.'lines-covered'; $lv=$n.'lines-valid'; $obj = Get-Content $jsonFile -Raw | ConvertFrom-Json; $covObj=[ordered]@{ target=$CovTarget; line_rate=$lr; branch_rate=$br; lines_covered=$lc; lines_valid=$lv; percent_lines= if($lr -ne $null){[Math]::Round($lr*100,2)} else {0}; percent_branches= if($br -ne $null){[Math]::Round($br*100,2)} else {$null} }; $obj | Add-Member -NotePropertyName coverage -NotePropertyValue $covObj -Force; $obj | ConvertTo-Json -Depth 10 | Set-Content $jsonFile -Encoding UTF8 } catch { Write-Host "Aviso: não foi possível injetar cobertura no JSON: $_" -ForegroundColor Yellow } }

if ($exit -eq 0) { Write-Host "✅ Testes OK" -ForegroundColor Green } elseif ($exit -eq 5) { Write-Host "⚠️  Pytest: nenhum teste coletado (exit 5)" -ForegroundColor Yellow } else { Write-Host "❌ Falhas nos testes (exit $exit)" -ForegroundColor Yellow }

Write-Host "Arquivos gerados em '$OutDir':" -ForegroundColor Cyan
Get-ChildItem $OutDir | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize

Write-Host ""; Write-Host "Para me enviar:  $(Resolve-Path $txtFile)" -ForegroundColor Magenta; if ($Json) { Write-Host "Ou (JSON+cov): $(Resolve-Path $jsonFile)" -ForegroundColor Magenta }

exit $exit
