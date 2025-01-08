local k = import 'k.libsonnet';  // Optional: import a Kubernetes library for helpers

{
  apiVersion: 'argoproj.io/v1alpha1',
  kind: 'Application',
  metadata: {
    name: 'argocd-mockup',
    namespace: 'argocd-mockup',
  },
  spec: {
    project: 'default',
    source: {
      repoURL: "https://github.com/Pokepasaj/mockup.git",
      targetRevision: 'main',
      path: 'k8s/dev',
    },
    destination: {
      server: 'https://kubernetes.default.svc',
      namespace: 'default',
    },
    syncPolicy: {
      automated: {
        prune: true,
        selfHeal: true,
      },
    },
  },
}