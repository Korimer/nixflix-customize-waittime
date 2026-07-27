{
  lib,
  pkgs,
}:
serviceName: serviceConfig:
pkgs.writeShellScript "${serviceName}-wait-for-api" (
  let
    mkSecureCurl = import ../../lib/mk-secure-curl.nix { inherit lib pkgs; };
    capitalizedName =
      lib.toUpper (builtins.substring 0 1 serviceName) + builtins.substring 1 (-1) serviceName;
    apiAttempts = builtins.toString serviceConfig.waitForApiAttempts;
    sleepSeconds = builtins.toString serviceConfig.sleepOnFailSeconds;
  in
  ''
    BASE_URL="http://${serviceConfig.hostConfig.bindAddress}:${builtins.toString serviceConfig.hostConfig.port}${serviceConfig.hostConfig.urlBase}/api/${serviceConfig.apiVersion}"

    echo "Waiting for ${capitalizedName} API to be available..."
    for i in {1..${apiAttempts}}; do
      if ${
        mkSecureCurl serviceConfig.apiKey {
          url = "$BASE_URL/system/status";
          extraArgs = "-f";
        }
      } >/dev/null 2>&1; then
        echo "${capitalizedName} API is available"
        exit 0
      fi
      echo "Waiting for ${capitalizedName} API... ($i/${apiAttempts})"
      sleep ${sleepSeconds}
    done

    echo "${capitalizedName} API not available after ${apiAttempts * sleepSeconds} seconds" >&2
    exit 1
  ''
)
