import subprocess
import json
import os


def run_cmd(command, as_json=True):
    result = None
    try:
        # Run the command and capture its output
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        # print(result.stdout)

        if not as_json:
            return result.stdout

        # Parse the JSON output
        json_output = json.loads(result.stdout)

        # Now you can work with the json_output
        # print("JSON Output: ", json_output)
        return json_output

    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e}")
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON output: {e}")


flakes_data_to_update = {
        "nixpkgs": "github:NixOS/nixpkgs/cdd2ef009676ac92b715ff26630164bb88fec4e0",
        "nixpkgs-unstable": "github:NixOS/nixpkgs/75a5ebf473cd60148ba9aec0d219f72e5cf52519",
        "flake-utils": "github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b",
        "nixos-generators": "github:nix-community/nixos-generators/0dd0205bc3f6d602ddb62aaece5f62a8715a9e85",
        "poetry2nix": "github:nix-community/poetry2nix/b9a98080beff0903a5e5fe431f42cde1e3e50d6b",
        "home-manager": "github:nix-community/home-manager/f6af7280a3390e65c2ad8fd059cdc303426cbd59",
        "nixGL": "github:guibou/nixGL/310f8e49a149e4c9ea52f1adf70cdc768ec53f8a",
}


def build_nix_flake_lock_override_input_command(input_flakes, flakes_data):
    command = ['nix', 'flake', 'lock']
    # command.extend(['--dry-run'])
    for flake in input_flakes:
        command.extend(['--override-input', flake, flakes_data[flake]])
    return command


# The command you want to run
command1 = ['nix', 'eval', '--json', '.#templates']

result1 =  run_cmd(command1)


def cmds(flake_reference):
    command_nix_flake_show = [
        'nix',
        'flake',
        'show',
        '--impure',
        flake_reference
    ]

    command_nix_flake_metadata = [
        'nix',
        'flake',
        'metadata',
        '--impure',
        flake_reference
    ]

    command_nix_build = [
        'nix',
        'build',
        '--cores',
        '6',
        '--no-link',
        '--print-build-logs',
        '--print-out-paths',
        '--impure',
        flake_reference
    ]

    command_nix_flake_check = [
        'nix',
        'flake',
        'check',
        '--cores',
        '6',
        '--impure',
        flake_reference
    ]
    _cmds = command_nix_flake_show, command_nix_flake_metadata, command_nix_build, command_nix_flake_check

    return _cmds


for template in result1:
    full_template_path = result1[template]["path"]

    template_relative_path = os.sep.join(full_template_path.split(os.sep)[4:])
    flake_reference = f'.?dir={template_relative_path}#'
    print(flake_reference)
   
    command2 = ['nix', 'flake', 'metadata', '--json', flake_reference ]

    result2 = run_cmd(command2)
    input_flakes = result2["locks"]["nodes"]["root"]["inputs"].keys()
    # print(result2)
    # print(input_flakes)

    result3 = build_nix_flake_lock_override_input_command(input_flakes, flakes_data_to_update)

    print(result3)

    for cmd in cmds(flake_reference):
        print(cmd)
        run_cmd(cmd, as_json=False)
    print()
