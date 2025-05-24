import os
import subprocess

from django.core.management import execute_from_command_line


current_file_path = os.path.abspath(__file__)
manage_py_path = os.path.join(os.path.dirname(current_file_path), 'manage.py')

def run_my_server():
    cmd = ['python', manage_py_path, 'runserver']
    subprocess.run(cmd)
