
secrets:
	sops secrets/kuri_exampleHost.yaml

update:
	nix flake update

build:
	sudo nh os build .

install:
	rm -f home/kuri/.gtkrc-2.0.backup /home/kuri/.gtkrc-2.0
	sudo nh os switch .

test:
	pre-commit run --all-files

build_clochette:
	nh os build .#clochette

install_clochette:
	nh os switch .#clochette --target-host guillaume@clochette.friloux.me --sudo --ask-sudo-password

secrets_clochette:
	sops secrets/clochette.yaml
