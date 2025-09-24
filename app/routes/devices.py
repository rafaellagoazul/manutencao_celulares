import re
from flask import Blueprint, request, render_template, current_app
from app.models import Dispositivo

bp = Blueprint('devices', __name__, url_prefix='')

@bp.get('/dispositivos')
def lista():
    q = request.args.get('q', '').strip()
    SessionLocal = current_app.config.get('SessionLocal')
    dispositivos = []
    if SessionLocal:
        s = SessionLocal()
        try:
            query = s.query(Dispositivo)
            if q:
                digits = re.sub(r'\D+', '', q)
                if digits:
                    query = query.filter(Dispositivo.imei1.contains(digits))
                else:
                    query = query.filter(Dispositivo.modelo.ilike(f"%{q}%"))
            dispositivos = query.all()
        finally:
            s.close()
    return render_template('dispositivos_list.html', dispositivos=dispositivos, q=q)
