_: {
  networking = {
    hostName = "clochette";
    networkmanager.enable = true;
    interfaces.eth0 = {
      ipv4.addresses = [
        {
          address = "51.159.34.135";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = "51.159.34.1";
    nameservers = ["51.159.47.28" "51.159.47.26"];
  };
}
