
secrets:
	nix-shell -p sops --run "sops secrets/kuri_exampleHost.yaml"

update:
	nix flake update

build:
	sudo nixos-rebuild build --flake .

install:
	rm -f home/kuri/.gtkrc-2.0.backup /home/kuri/.gtkrc-2.0
	sudo nixos-rebuild switch --flake .

test:
	pre-commit run --all-files

build_clochette:
	nixos-rebuild build --flake .#clochette

install_clochette:
	nixos-rebuild switch --flake .#clochette --target-host guillaume@clochette.friloux.me --sudo --ask-sudo-password

secrets_clochette:
	nix-shell -p sops --run "sops secrets/clochette.yaml"
