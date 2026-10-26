_: {
  # IPv4 en DHCP. L'IPv6 (2001:41d0:404:200::487d/128) est statique chez OVH
  # et viendra dans une étape séparée.
  networking = {
    hostName = "skitarii";
    useDHCP = true;
  };

  # SSH public tant que Tailscale n'est pas en place.
  services.openssh.openFirewall = true;
}
