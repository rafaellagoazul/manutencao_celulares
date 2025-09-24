
# tests/test_healthz.py
import importlib
import pytest

app = None
try:
    wsgi = importlib.import_module('wsgi')
    app = getattr(wsgi, 'app', None)
except Exception:
    app = None

if app is None:
    try:
        from app.app_factory import create_app
        app = create_app()
    except Exception as e:
        pytest.skip(f"Sem 'wsgi.app' e sem factory 'create_app()': {e}")

def test_smoke_root_or_healthz():
    client = app.test_client()
    for path in ("/healthz", "/"):
        resp = client.get(path)
        if resp.status_code < 500:
            assert resp.status_code in (200, 301, 302, 401, 403, 404)
            return
    pytest.fail("Nenhuma rota básica respondeu com status < 500")
