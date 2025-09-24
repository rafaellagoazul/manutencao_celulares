try:
    # Tenta usar a factory real do projeto (recomendado)
    from app.app_factory import create_app
    app = create_app()
except Exception:
    # Fallback mínimo para desenvolvimento/deploy inicial
    from flask import Flask
    app = Flask(__name__)

    @app.get('/')
    def index():
        return '<h1>Manutenção de Celulares</h1><p>App rodando. Visite <code>/healthz</code>.</p>'

    @app.get('/healthz')
    def healthz():
        return {'status': 'ok'}
