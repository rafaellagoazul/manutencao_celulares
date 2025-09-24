from flask import Blueprint, render_template, current_app
from app.models import Dispositivo, Pessoa

bp = Blueprint('main', __name__)

@bp.get('/')
def index():
    SessionLocal = current_app.config.get('SessionLocal')
    total_dispositivos = total_pessoas = 0
    if SessionLocal:
        s = SessionLocal()
        try:
            total_dispositivos = s.query(Dispositivo).count()
            total_pessoas = s.query(Pessoa).count()
        finally:
            s.close()
    totais = {'dispositivos': total_dispositivos, 'pessoas': total_pessoas}
    return render_template('index.html', totais=totais)

@bp.get('/healthz')
def healthz_bp():
    return {'status': 'ok'}
