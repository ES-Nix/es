{ pkgs, lib, ... }:
let
  cavemanHooks = "${pkgs.caveman}/lib/caveman/src/hooks";
  cavemanSkills = "${pkgs.caveman}/lib/caveman/skills";
  memPlugin = "${pkgs.claude-mem}/lib/claude-mem/plugin";
  node = "${pkgs.nodejs}/bin/node";
  bun = pkgs.claude-mem.passthru.bunBin;
  superpowersDir = "${pkgs.superpowers-plugin}/lib/superpowers";

  memHook = { action, timeout ? 60 }: {
    type = "command";
    shell = "bash";
    command = "CLAUDE_PLUGIN_ROOT=${memPlugin} ${bun} run ${memPlugin}/scripts/worker-service.cjs hook claude-code ${action}";
    inherit timeout;
  };

  settings = {
    alwaysThinkingEnabled = true;
    projects."/etc/nixos".hasTrustDialogAccepted = true;
    mcpServers = {
      nixos = {
        type = "stdio";
        command = "mcp-nixos";
        args = [ ];
        env = { };
      };
      "aws-api" = {
        type = "stdio";
        command = "aws-api-mcp-server";
        args = [ ];
        env = { };
      };
      "context7" = {
        type = "stdio";
        command = "context7-mcp";
        args = [ ];
        env = { };
      };
    };
    hooks = {
      PreToolUse = [
        {
          matcher = "Bash";
          hooks = [{ type = "command"; command = "rtk hook claude"; }];
        }
        {
          matcher = "Read";
          hooks = [ (memHook { action = "file-context"; }) ];
        }
      ];
      SessionStart = [
        {
          hooks = [{
            type = "command";
            command = "${node} ${cavemanHooks}/caveman-activate.js";
            marker = "caveman-activate";
            timeout = 5;
            statusMessage = "Loading caveman mode...";
          }];
        }
        {
          matcher = "startup|clear|compact";
          hooks = [
            {
              type = "command";
              shell = "bash";
              timeout = 60;
              command = "CLAUDE_PLUGIN_ROOT=${memPlugin} ${bun} run ${memPlugin}/scripts/worker-service.cjs start; echo '{\"continue\":true,\"suppressOutput\":true}'";
            }
            (memHook { action = "context"; })
            {
              type = "command";
              shell = "bash";
              command = "CLAUDE_PLUGIN_ROOT=${superpowersDir} bash ${superpowersDir}/hooks/session-start";
              marker = "superpowers-session-start";
              timeout = 10;
              statusMessage = "Loading superpowers...";
            }
          ];
        }
      ];
      UserPromptSubmit = [
        {
          hooks = [{
            type = "command";
            command = "${node} ${cavemanHooks}/caveman-mode-tracker.js";
            marker = "caveman-mode-tracker";
            timeout = 5;
          }];
        }
        {
          hooks = [ (memHook { action = "session-init"; }) ];
        }
      ];
      PostToolUse = [{
        matcher = "*";
        hooks = [ (memHook { action = "observation"; timeout = 120; }) ];
      }];
      Stop = [{
        hooks = [ (memHook { action = "summarize"; timeout = 120; }) ];
      }];
    };
    statusLine = {
      type = "command";
      command = "bash ${cavemanHooks}/caveman-statusline.sh";
    };
  };

  settingsFile = pkgs.writeText "claude-settings.json" (builtins.toJSON settings);

  rtkMd = pkgs.writeText "claude-RTK.md" ''
    # RTK - Rust Token Killer

    **Usage**: Token-optimized CLI proxy (60-90% savings on dev operations)

    ## Meta Commands (always use rtk directly)

    ```bash
    rtk gain              # Show token savings analytics
    rtk gain --history    # Show command usage history with savings
    rtk discover          # Analyze Claude Code history for missed opportunities
    rtk proxy <cmd>       # Execute raw command without filtering (for debugging)
    ```

    ## Installation Verification

    ```bash
    rtk --version         # Should show: rtk X.Y.Z
    rtk gain              # Should work (not "command not found")
    which rtk             # Verify correct binary
    ```

    Warning: If rtk gain fails, you may have reachingforthejack/rtk (Rust Type Kit) installed instead.

    ## Hook-Based Usage

    All other commands are automatically rewritten by the Claude Code hook.
    Example: git status -> rtk git status (transparent, 0 tokens overhead)

    Refer to CLAUDE.md for full command reference.
  '';
in
{
  system.activationScripts.claudeMcpSettings = {
    text = ''
            CLAUDE_DIR="/home/nixuser/.claude"
            mkdir -p "$CLAUDE_DIR/hooks" "$CLAUDE_DIR/commands"

            cp ${settingsFile} "$CLAUDE_DIR/settings.json"
            chmod 644 "$CLAUDE_DIR/settings.json"
            chown nixuser:nixgroup "$CLAUDE_DIR/settings.json"

            ln -sf ${cavemanHooks}/caveman-activate.js     "$CLAUDE_DIR/hooks/caveman-activate.js"
            ln -sf ${cavemanHooks}/caveman-mode-tracker.js "$CLAUDE_DIR/hooks/caveman-mode-tracker.js"
            ln -sf ${cavemanHooks}/caveman-statusline.sh   "$CLAUDE_DIR/hooks/caveman-statusline.sh"

            for skill_dir in ${cavemanSkills}/*; do
              skill_name=$(basename "$skill_dir")
              ln -sf "$skill_dir/SKILL.md" "$CLAUDE_DIR/commands/$skill_name.md"
            done

            for skill_dir in ${superpowersDir}/skills/*; do
              skill_name=$(basename "$skill_dir")
              ln -sf "$skill_dir/SKILL.md" "$CLAUDE_DIR/commands/$skill_name.md"
            done

            cp ${rtkMd} "$CLAUDE_DIR/RTK.md"

            grep -qF "@RTK.md" "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null \
              || echo "@RTK.md" >> "$CLAUDE_DIR/CLAUDE.md"

            # Merge declarative mcpServers into .claude.json for all projects
            CLAUDE_JSON="/home/nixuser/.claude.json"
            if [ -f "$CLAUDE_JSON" ]; then
              ${pkgs.python3}/bin/python3 -c "
      import json, sys
      path = sys.argv[1]
      data = json.load(open(path))
      mcps = {
        'nixos':    {'type': 'stdio', 'command': 'mcp-nixos',          'args': [], 'env': {}},
        'aws-api':  {'type': 'stdio', 'command': 'aws-api-mcp-server', 'args': [], 'env': {}},
        'context7': {'type': 'stdio', 'command': 'context7-mcp',       'args': [], 'env': {}},
      }
      for proj in data.get('projects', {}).values():
        proj.setdefault('mcpServers', {}).update(mcps)
      open(path, 'w').write(json.dumps(data))
      " "$CLAUDE_JSON"
              chown nixuser:nixgroup "$CLAUDE_JSON"
            fi

            chown -R nixuser:nixgroup "$CLAUDE_DIR/hooks" "$CLAUDE_DIR/commands" \
              "$CLAUDE_DIR/RTK.md" "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null || true
    '';
    deps = [ ];
  };
}
