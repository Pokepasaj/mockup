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
              imagePullPolicy: 'Always', 
            },
          ],
          dnsPolicy: 'None',
          dnsConfig: {
            nameservers: [
              '8.8.8.8',
              '8.8.4.4',
            ],
            options: [
              { name: 'ndots', value: '5' },
            ],
          },
        },
      },
    },
  },
}
