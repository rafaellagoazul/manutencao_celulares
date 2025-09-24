from flask import Blueprint, render_template

bp = Blueprint('maintenance', __name__, url_prefix='')

@bp.get('/manutencoes')
def lista():
    manutencoes = []
    return render_template('manutencoes_list.html', manutencoes=manutencoes)
