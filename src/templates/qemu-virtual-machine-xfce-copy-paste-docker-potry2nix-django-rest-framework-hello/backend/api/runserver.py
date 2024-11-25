import subprocess

def run_my_server():
    cmd = ['python', 'api/manage.py', 'runserver']
    subprocess.run(cmd)
