{
  simpleDeployment(p):: {
    apiVersion: 'apps/v1',
    kind: 'Deployment',
    metadata: {
      name: p.name,
      labels: p.labels,
    },
    spec: {
      replicas: p.replicas,
      selector: {
        matchLabels: p.labels,
      },
      template: {
        metadata: {
          labels: p.labels,
        },
        spec: {
          containers: [
            {
              name: p.name,
              image: p.image,
              ports: [
                {
                  containerPort: p.containerPort,
                },
              ],
              imagePullPolicy: 'Never', 
            },
          ],
        },
      },
    },
  },
}