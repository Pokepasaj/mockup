local k = import 'k.libsonnet';  // Optional: import a Kubernetes library for helpers

{
  apiVersion: 'argoproj.io/v1alpha1',
  kind: 'Application',
  metadata: {
    name: 'argocd-mockup',
    namespace: 'argocd',
  },
  spec: {
    project: 'default',
    source: {
      repoURL: "https://github.com/Pokepasaj/mockup.git",
      targetRevision: 'main',
      path: 'k8s/dev',
      directory: {
        recurse: true,
        include: "{k8s/dev/*.yaml,k8s/dev/**/*.yaml,src/**/*}",
        jsonnet: {
          libs: [
            '../k8s/easyproject',
            'vendor/tpv-gitops/lib',
          ],
        },
      },
    },
    destination: {
      server: 'https://kubernetes.default.svc',
      namespace: 'default',
    },
    syncPolicy: {
      automated: {
        prune: false,
        selfHeal: true,
      },
    },
  },
}