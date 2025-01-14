{
  simpleIngress(p):: {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'Ingress',
    metadata: {
      name: p.name,
      annotations: p.annotations,
    },
    spec: {
      rules: [
        {
          host: p.host,
          http: {
            paths: [
              {
                path: p.path,
                pathType: 'Prefix',
                backend: {
                  service: {
                    name: p.serviceName,
                    port: {
                      number: p.servicePort,  // Ensure this is the correct port for the service
                    },
                  },
                },
              },
            ],
          },
        },
      ],
    },
  },
}
