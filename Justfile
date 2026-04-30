
secrets:
	sops secrets/kuri_exampleHost.yaml

update:
	nix flake update

build:
	nh os build .

install:
	rm -f home/kuri/.gtkrc-2.0.backup /home/kuri/.gtkrc-2.0
	nh os switch .

test:
	pre-commit run --all-files

build_clochette:
	nh os build .#clochette

install_clochette:
	nixos-rebuild switch --flake .#clochette --target-host guillaume@clochette.friloux.me --sudo --ask-sudo-password

secrets_clochette:
	sops secrets/clochette.yaml
