local k = import "github.com/jsonnet-libs/k8s-libsonnet/1.32/main.libsonnet";

local appName = "book-review-app";
local imageTag = "latest";
local containerPort = 8080;
local servicePort = 80;
local targetPort = 8080;

{
  // Deployment Manifest
  deployment: k.apps.v1.deployment {
    metadata: {
      name: appName,
    },
    spec: {
      replicas: 1,
      selector: {
        matchLabels: {
          app: appName,
        },
      },
      template: {
        metadata: {
          labels: {
            app: appName,
          },
        },
        spec: {
          containers: [
            k.core.v1.container {
              name: appName,
              image: appName + ":" + imageTag,
              ports: [
                k.core.v1.containerPort {
                  containerPort: containerPort,
                },
              ],
              env: [
                k.core.v1.envVar {
                  name: "APP_ENV",
                  value: "production",
                },
                k.core.v1.envVar {
                  name: "DATABASE_URL",
                  value: "mysql://db.example.com",
                },
              ],
            },
          ],
        },
      },
    },
  },

  // Service Manifest
  service: k.core.v1.service {
    metadata: {
      name: appName + "-service",
    },
    spec: {
      selector: {
        app: appName,
      },
      ports: [
        k.core.v1.servicePort {
          protocol: "TCP",
          port: servicePort,
          targetPort: targetPort,
        },
      ],
    },
  },
}
