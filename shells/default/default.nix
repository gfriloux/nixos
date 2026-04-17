{
  inputs,
  mkShell,
  system,
  ...
}: let
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };
in
  mkShell {
    packages = with pkgs; [
      deadnix
      statix
      alejandra
      pre-commit
      serie
      tokei
    ];

    shellHook = ''
          echo "[nixos] Ready."

          if [ ! -f .pre-commit-config.yaml ]; then
            echo "Generating .pre-commit-config.yaml..."
            cat > .pre-commit-config.yaml <<'EOF'
      ---
      repos:
        - repo: local
          hooks:
            - id: alejandra
              name: alejandra
              language: system
              entry: alejandra --check
              files: \.nix$
              pass_filenames: true
            - id: deadnix
              name: deadnix
              language: system
              entry: deadnix --fail
              files: \.nix$
              pass_filenames: true
            - id: statix
              name: statix
              language: system
              entry: statix check
              pass_filenames: false
      EOF
          else
            echo ".pre-commit-config.yaml already exists. Skipping generation."
          fi

          if [ -d .git ]; then
            if [ ! -f .git/hooks/pre-commit ]; then
              echo "Installing pre-commit hook..."
              pre-commit install -f --install-hooks
            fi
          else
            echo "Not a git repository. Skipping pre-commit installation."
          fi
    '';
  }
