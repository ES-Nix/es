import os
import sys
from django.core.management import execute_from_command_line


_api_dir = os.path.dirname(os.path.abspath(__file__))


def run_my_server():
    # When run via Nix entry point, this dir (api/) must be on sys.path so
    # 'drfhello' resolves as a top-level module (same as 'python manage.py' does).
    if _api_dir not in sys.path:
        sys.path.insert(0, _api_dir)
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "drfhello.settings")
    execute_from_command_line(["manage.py", "runserver", "0.0.0.0:8000", "--noreload"])
