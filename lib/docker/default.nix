_: {
  docker = {
    mkHealthCheck = {
      cmd,
      startPeriod ? "30s",
    }: [
      "--health-cmd=${cmd}"
      "--health-interval=30s"
      "--health-timeout=10s"
      "--health-start-period=${startPeriod}"
      "--health-retries=3"
    ];

    mkNetwork = pkgs: name: {
      path = [pkgs.docker];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "${pkgs.docker}/bin/docker network rm -f ${name}";
      };
      script = ''
        docker network inspect ${name} || docker network create ${name}
      '';
    };
  };
}
