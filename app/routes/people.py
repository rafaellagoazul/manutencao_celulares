from flask import Blueprint, render_template

bp = Blueprint('people', __name__, url_prefix='')

@bp.get('/pessoas')
def lista():
    pessoas = []
    return render_template('pessoas_list.html', pessoas=pessoas)
