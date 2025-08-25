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
    except Exception as e:
        print(f"Error desconhecido output: {e}")


def build_nix_flake_lock_override_input_command(input_flakes, flakes_data, flake_reference):
    command = 'nix flake lock --verbose'.split()
    # command.extend(['--dry-run'])
    for flake in input_flakes:
        command.extend(['--override-input', flake, flakes_data[flake]])
        # print("flake:", flake, "data:", flakes_data[flake])

    command.append(flake_reference)
    # print("command:", ' '.join(command))
    return command


def cmds(flake_reference):
    command_nix_flake_show = ('nix flake show --impure ' + flake_reference).split()

    command_nix_flake_metadata = ('nix flake metadata --impure ' + flake_reference).split()

    command_nix_build = ('nix build --cores 6 --no-link --print-build-logs --print-out-paths --impure ' + flake_reference).split()

    command_nix_flake_check = ('nix flake check --cores 6 --impure ' + flake_reference).split()

    _cmds = command_nix_flake_show, command_nix_flake_metadata, command_nix_build, command_nix_flake_check

    return _cmds


def aux(all_templates, flakes_data_to_update):
    for template in all_templates:
        full_template_path = all_templates[template]["path"]

        template_relative_path = os.sep.join(full_template_path.split(os.sep)[4:])
        flake_reference = f'.?dir={template_relative_path}#'
        print("flake reference:", flake_reference)
    
        command2 = ('nix flake metadata --json ' + flake_reference).split()
        flake_template_metadata = run_cmd(command2)
        input_flakes = flake_template_metadata["locks"]["nodes"]["root"]["inputs"].keys()
        print("input_flakes:", input_flakes)
        command_nix_flake_lock_override = build_nix_flake_lock_override_input_command(input_flakes, flakes_data_to_update, flake_reference)
        result3 = run_cmd(command_nix_flake_lock_override, as_json=False)
        print("result3:", result3)

        for cmd in cmds(flake_reference):
            # print(cmd)
            run_cmd(cmd, as_json=False)
        print()


flakes_data_to_update = {
        "nixpkgs": "github:NixOS/nixpkgs/fd487183437963a59ba763c0cc4f27e3447dd6dd",
        "nixpkgs-unstable": "github:NixOS/nixpkgs/75a5ebf473cd60148ba9aec0d219f72e5cf52519",
        "flake-utils": "github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b",
        "nixos-generators": "github:nix-community/nixos-generators/0dd0205bc3f6d602ddb62aaece5f62a8715a9e85",
        "poetry2nix": "github:nix-community/poetry2nix/b9a98080beff0903a5e5fe431f42cde1e3e50d6b",
        "home-manager": "github:nix-community/home-manager/83665c39fa688bd6a1f7c43cf7997a70f6a109f9",
        "nixGL": "github:guibou/nixGL/310f8e49a149e4c9ea52f1adf70cdc768ec53f8a",
}

# The command you want to run
command1 = 'nix eval --json .#templates'.split()
all_templates =  run_cmd(command1)
aux(all_templates, flakes_data_to_update)


# f6af7280a3390e65c2ad8fd059cdc303426cbd59
# 83665c39fa688bd6a1f7c43cf7997a70f6a109f9