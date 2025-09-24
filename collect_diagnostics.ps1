
<# Coleta diag + pytest + cobertura e empacota em artifacts_diag\bundle.zip #>
param([string]$OutDir="artifacts_diag",[string]$CovTarget="app",[switch]$Json)
$ErrorActionPreference="Stop"; $ProgressPreference="SilentlyContinue"
[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new()
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)

$venv=".\.venv\Scripts\Activate.ps1"
if(!(Test-Path $venv)){ "ERRO: venv não encontrada em $venv"; exit 1 }
& $venv
$env:PYTHONIOENCODING="utf-8"

New-Item -Force -ItemType Directory -Path $OutDir | Out-Null
$diag=Join-Path $OutDir "diagnostics.txt"
$txt =Join-Path $OutDir "tests_report.txt"
$json=Join-Path $OutDir "tests_report.json"
$jxml=Join-Path $OutDir "junit.xml"
$cxml=Join-Path $OutDir "coverage.xml"
$tree=Join-Path $OutDir "tree.txt"
$freeze=Join-Path $OutDir "pip_freeze.txt"
$collect=Join-Path $OutDir "collect_only.txt"
$zip =Join-Path $OutDir "bundle.zip"
Remove-Item $txt,$json,$jxml,$cxml,$tree,$freeze,$collect,$zip -Force -ErrorAction SilentlyContinue

"== Diagnostics $(Get-Date -Format s)" | Out-File $diag
"cwd: $(Get-Location)"                | Out-File $diag -Append
"Python: $(python --version)"         | Out-File $diag -Append
"Pytest: $(pytest --version 2>$null)" | Out-File $diag -Append
"pip: $(pip --version)"               | Out-File $diag -Append
"Encoding Console: $([Console]::OutputEncoding.WebName)" | Out-File $diag -Append

"== Tree (nível 1..3)" | Out-File $tree
Get-ChildItem . -Depth 3 | % { $_.FullName } | Out-File $tree -Append
pip freeze | Out-File $freeze

python -m pip install --upgrade pip | Out-Null
if(Test-Path .\requirements.txt){ pip install -r requirements.txt | Out-Null }
pip install pytest-cov | Out-Null
if($Json){ pip install pytest-json-report | Out-Null }

"== Pytest --collect-only" | Out-File $collect
pytest --collect-only -q 2>&1 | Out-File $collect -Append

$args=@(
  "-q","-r","a","--disable-warnings","--maxfail=1",
  "--junitxml",$jxml,"--cov=$CovTarget","--cov-branch",
  "--cov-report","term-missing:skip-covered","--cov-report","xml:$cxml"
)
if($Json){ $args += @("--json-report","--json-report-file",$json) }

"== Test run: $(Get-Date -Format s)" | Out-File $txt
pytest @args 2>&1 | Tee-Object -FilePath $txt -Append
$exit=$LASTEXITCODE
"== Exit code: $exit" | Out-File $txt -Append

function Get-DoubleInvariant([string]$val){ if([string]::IsNullOrWhiteSpace($val)){return $null}; $styles=[System.Globalization.NumberStyles]::Float; $ci=[System.Globalization.CultureInfo]::InvariantCulture; $out=0.0; if([System.Double]::TryParse($val,$styles,$ci,[ref]$out)){return $out}; return $null }
function Add-CovSummary([string]$xml,[string]$out){
  if(!(Test-Path $xml)){ "`n== Coverage summary: coverage.xml NÃO encontrado" | Out-File $out -Append; return }
  try{ [xml]$cov=Get-Content $xml -Raw; $n=$cov.coverage; $lr=Get-DoubleInvariant ($n.'line-rate'); $br=Get-DoubleInvariant ($n.'branch-rate'); $lc=$n.'lines-covered'; $lv=$n.'lines-valid'; $pct= if($lr -ne $null){[Math]::Round($lr*100,2)} else {0}; $pctb= if($br -ne $null){[Math]::Round($br*100,2)} else {$null}; "`n== Coverage summary" | Out-File $out -Append; if($lc -and $lv){ "Lines: $pct%  ($lc/$lv)" | Out-File $out -Append } else { "Lines: $pct%" | Out-File $out -Append }; if($pctb -ne $null){ "Branches: $pctb%" | Out-File $out -Append } } catch { "`n== Coverage summary: erro ao ler coverage.xml: $_" | Out-File $out -Append }
}
Add-CovSummary $cxml $txt

if($Json -and (Test-Path $json) -and (Test-Path $cxml)){
  try{ [xml]$cov=Get-Content $cxml -Raw; $n=$cov.coverage; $lr=Get-DoubleInvariant ($n.'line-rate'); $br=Get-DoubleInvariant ($n.'branch-rate'); $lc=$n.'lines-covered'; $lv=$n.'lines-valid'; $obj=Get-Content $json -Raw | ConvertFrom-Json; $covObj=[ordered]@{ target=$CovTarget; line_rate=$lr; branch_rate=$br; lines_covered=$lc; lines_valid=$lv; percent_lines= if($lr -ne $null){[Math]::Round($lr*100,2)} else {0}; percent_branches= if($br -ne $null){[Math]::Round($br*100,2)} else {$null} }; $obj | Add-Member -NotePropertyName coverage -NotePropertyValue $covObj -Force; $obj | ConvertTo-Json -Depth 15 | Set-Content $json -Encoding UTF8 } catch {}
}

if(Test-Path $zip){ Remove-Item $zip -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($OutDir,$zip)
Write-Host "`nMe envie:  $zip" -ForegroundColor Magenta
exit $exit
