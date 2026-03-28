{ ... }:
{
  security.rtkit.enable = true;
  security = {
    doas.enable = false;
    sudo.enable = true;
  };
}
