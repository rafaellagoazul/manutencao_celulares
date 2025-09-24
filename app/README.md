# Pasta app/

Substitua este diretório pela **sua** pasta `app/` real do projeto.
O `wsgi.py` na raiz tenta importar `create_app()` de `app.app_factory`.
Se não encontrar, um fallback mínimo com `/healthz` será usado.
