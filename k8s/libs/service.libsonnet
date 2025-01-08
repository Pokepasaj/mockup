{
  LoadBalancer(p):: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: p.name,
      namespace: p.namespace,
      labels: p.labels,
    },
    spec: {
      type: 'LoadBalancer',
      ports: [
        {
          port: p.port,
          targetPort: p.targetPort,
          protocol: 'TCP',
        },
      ],
      selector: p.selector,
    },
  },

  NodePort(p):: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: p.name,
      namespace: p.namespace,
      labels: p.labels,
    },
    spec: {
      type: 'NodePort',
      ports: [
        {
          port: p.port,
          targetPort: p.targetPort,
          protocol: 'TCP',
        },
      ],
      selector: p.selector,
    },
  },
}