import logging
from logging.handlers import RotatingFileHandler
from datetime import datetime
from pathlib import Path
from flask import Flask, send_from_directory, jsonify
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.config import load_config
from app.models import Base, Dispositivo, Pessoa
# Blueprints
from app.routes.main import bp as main_bp
from app.routes.people import bp as people_bp
from app.routes.devices import bp as devices_bp
from app.routes.maintenance import bp as maintenance_bp

def create_app(config_overrides=None):
    cfg = load_config(config_overrides)
    app_dir = Path(__file__).resolve().parent
    root_dir = app_dir.parent

    # Garante diretórios
    Path(cfg['DB_PATH']).parent.mkdir(parents=True, exist_ok=True)
    Path(cfg['UPLOAD_DIR']).mkdir(parents=True, exist_ok=True)

    app = Flask(
        __name__,
        template_folder=str(app_dir / 'templates'),
        static_folder=str(app_dir / 'static')
    )
    app.config.update(cfg)

    # Logs rotativos -> raiz/logs
    log_path = root_dir / 'logs' / 'app.log'
    log_path.parent.mkdir(parents=True, exist_ok=True)
    handler = RotatingFileHandler(log_path, maxBytes=1_000_000, backupCount=3)
    handler.setLevel(logging.INFO)
    fmt = logging.Formatter('%(asctime)s %(levelname)s [%(name)s] %(message)s')
    handler.setFormatter(fmt)
    app.logger.addHandler(handler)
    app.logger.setLevel(logging.INFO)

    # Banco de dados
    engine = create_engine(f"sqlite:///{cfg['DB_PATH']}", echo=False, future=True)
    Base.metadata.create_all(engine)
    SessionLocal = sessionmaker(bind=engine)
    app.config['SessionLocal'] = SessionLocal

    # Jinja globals
    @app.context_processor
    def inject_now():
        return {'now': datetime.now}

    # Registro dos blueprints
    app.register_blueprint(main_bp)     # '/', '/healthz'
    app.register_blueprint(people_bp)   # '/pessoas'
    app.register_blueprint(devices_bp)  # '/dispositivos'
    app.register_blueprint(maintenance_bp)  # '/manutencoes'

    # Favicon (evita 404)
    @app.get('/favicon.ico')
    def favicon():
        fav = Path(app.static_folder) / 'favicon.ico'
        if fav.exists():
            return send_from_directory(app.static_folder, 'favicon.ico', mimetype='image/vnd.microsoft.icon')
        return '', 204

    # Debug dump (apenas em DEBUG/TESTING)
    @app.get('/__debugdump')
    def __debugdump():
        if not (app.debug or app.testing):
            return jsonify({'error': 'debug desabilitado'}), 403
        try:
            s = SessionLocal()
            total_dispositivos = s.query(Dispositivo).count()
            total_pessoas = s.query(Pessoa).count()
        except Exception:
            total_dispositivos = total_pessoas = None
        finally:
            try:
                s.close()
            except Exception:
                pass
        data = {
            'debug': app.debug,
            'testing': app.testing,
            'db_path': str(cfg['DB_PATH']),
            'routes': sorted([str(r) for r in app.url_map.iter_rules()]),
            'totais': {
                'dispositivos': total_dispositivos,
                'pessoas': total_pessoas
            }
        }
        return jsonify(data)

    app.logger.info('Application initialized')
    return app
