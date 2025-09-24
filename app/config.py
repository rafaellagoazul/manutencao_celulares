import os
from pathlib import Path
from dotenv import load_dotenv

DEFAULT_DB_PATH = 'instance/app.db'
DEFAULT_UPLOAD_DIR = 'instance/uploads'

def load_config(overrides: dict | None = None) -> dict:
    load_dotenv(override=True)
    cfg = {
        'DB_PATH': os.environ.get('DB_PATH', DEFAULT_DB_PATH),
        'UPLOAD_DIR': os.environ.get('UPLOAD_DIR', DEFAULT_UPLOAD_DIR),
        'SECRET_KEY': os.environ.get('SECRET_KEY', 'dev-secret'),
        'MAX_CONTENT_LENGTH': int(os.environ.get('MAX_CONTENT_LENGTH', 20 * 1024 * 1024)),  # 20MB
        'ALLOWED_EXTENSIONS': set((os.environ.get('ALLOWED_EXTENSIONS') or 'pdf,jpg,jpeg,png,txt').split(',')),
    }
    if overrides:
        cfg.update(overrides)
    cfg['DB_PATH'] = str(Path(cfg['DB_PATH']))
    cfg['UPLOAD_DIR'] = str(Path(cfg['UPLOAD_DIR']))
    return cfg
