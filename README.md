# Manutenção de Celulares — Render + GitHub Actions + UI Darkly + Testes

Este pacote integra:
- **UI** com tema **Darkly** (Bootswatch) em `app/templates` e `app/static`.
- **Servidor**: `wsgi.py` com fallback e rota `/healthz`.
- **Deploy** no **Render** via `Procfile` e workflow do **GitHub Actions**.
- **Scripts Windows**:
  - `run_windows.ps1` → roda localmente com **Waitress** (Windows).
  - `run_tests_collect_logs.ps1` → executa **pytest** e gera `tests_report.txt` (+ cobertura e JSON opcional).
  - `collect_diagnostics.ps1` → coleta diagnósticos + testes + cobertura e empacota em `artifacts_diag/bundle.zip`.

## Como usar (local)
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
# Rodar com Waitress (Windows):
./run_windows.ps1
# Testes + cobertura:
./run_tests_collect_logs.ps1 -CovTarget app -Json
```

## Deploy no Render
- Build: `pip install -r requirements.txt`
- Start: `gunicorn wsgi:app`
- (Opcional) Env: `PYTHON_VERSION=3.12.6`

## CI/CD GitHub Actions
- Adicione no repositório (Settings → Secrets and variables → Actions):
  - `RENDER_API_KEY`
  - `RENDER_SERVICE_ID`
- A cada push no `main`: roda testes e dispara deploy.

> Produção: prefira **Postgres** (Render) e defina `DATABASE_URL`. SQLite serve para testes.
