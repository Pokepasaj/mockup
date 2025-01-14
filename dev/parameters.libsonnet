{
 bookApp: {
    name: 'book-review-app',
    labels: { app: 'book-review-app' },
    replicas: 3,
    image: 'pokepasaj/book-review-app',
    port: 8080,
    containerPort: 8080,
    targetPort: 443,
    selector: { app: 'book-review-app' },
    namespace: 'argocd-mockup',
    serviceType: 'NodePort',
    nodePort: 30080,  // NodePort for external access
    host: 'localhost',  // Set this to 'localhost' or any external host as needed
    path: '/',
    annotations: { 'nginx.ingress.kubernetes.io/rewrite-target': '/' },
    serviceName: 'book-review-app',
    servicePort: 8080,
  },
}
