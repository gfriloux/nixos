_: {
  # IPv4 en DHCP. L'IPv6 est statique : OVH n'envoie pas de router
  # advertisement sur ce VPS.
  networking = {
    hostName = "skitarii";
    useDHCP = true;
    interfaces.ens3.ipv6 = {
      addresses = [
        {
          address = "2001:41d0:404:200::487d";
          prefixLength = 128;
        }
      ];
      # Avec un /128, la passerelle n'est pas dans notre préfixe : sans cette
      # route le noyau ne sait pas qu'elle est joignable directement sur ens3.
      routes = [
        {
          address = "2001:41d0:404:200::1";
          prefixLength = 128;
        }
      ];
    };
    defaultGateway6 = {
      address = "2001:41d0:404:200::1";
      interface = "ens3";
    };
  };

  services.tailscale.enable = true;
  networking.firewall.trustedInterfaces = ["tailscale0"];

  # SSH joignable uniquement via le tailnet (tailscale0, de confiance).
  services.openssh.openFirewall = false;
}
