
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
	nh os build .#clochette -d never

install_clochette:
	nixos-rebuild switch --flake .#clochette --target-host guillaume@clochette.friloux.me --sudo --ask-sudo-password

secrets_clochette:
	sops secrets/clochette.yaml

build_rogueleader:
	nh os build .#RogueLeader -d never

install_rogueleader:
	nixos-rebuild switch --flake .#RogueLeader --target-host guillaume@rogueleader.home --use-remote-sudo --ask-sudo-password

home_rogueleader:
	nix run nixpkgs#home-manager -- switch --flake .#"guillaume@RogueLeader" -b backup --target-host guillaume@rogueleader.home

secrets_rogueleader:
	sops secrets/RogueLeader.yaml

scan:
	nix eval --raw \
		'.#nixosConfigurations.clochette.config.virtualisation.oci-containers.containers' \
		--apply 'c: builtins.concatStringsSep "\n" (map (x: x.image) (builtins.attrValues c))' \
		| xargs -I{} trivy image --severity HIGH,CRITICAL {}

docs-install:
	cd docs && npm install

docs-dev: docs-install
	cd docs && npm run dev

docs-build: docs-install
	cd docs && npm run build

docs-preview: docs-build
	cd docs && npm run preview
