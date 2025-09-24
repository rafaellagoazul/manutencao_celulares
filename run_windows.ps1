
# Script para rodar o app Flask no Windows usando Waitress (com diagnósticos)
Write-Host "=== Iniciando aplicação com Waitress no Windows ==="

$venvActivate = ".\.venv\Scripts\Activate.ps1"
if (-Not (Test-Path $venvActivate)) {
    Write-Host "ERRO: Ambiente virtual não encontrado."; Write-Host "Crie com: python -m venv .venv"; Read-Host "ENTER para sair"; exit 1
}
& $venvActivate

Write-Host "Instalando dependências..."
pip install --upgrade pip | Out-Null
pip install -r requirements.txt | Out-Null
pip install waitress | Out-Null

Write-Host "Verificando 'wsgi:app'..."
python -c "import sys; import wsgi; sys.exit(0 if hasattr(wsgi,'app') else 2)"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: 'wsgi.app' não encontrado. Confirme que wsgi.py exporta 'app'."; Read-Host "ENTER"; exit 1
}

$busy = (netstat -ano | Select-String ":8000").Length -gt 0
$listen = if ($busy) { "127.0.0.1:8080" } else { "127.0.0.1:8000" }
Write-Host "Iniciando servidor Waitress em http://$listen ..."
python -m waitress --expose-tracebacks --listen=$listen wsgi:app
$code = $LASTEXITCODE
if ($code -ne 0) { Write-Host "Servidor encerrou com código $code"; Read-Host "ENTER" }
