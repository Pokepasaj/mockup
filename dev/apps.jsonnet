local EasyProject = import '../k8s/easyproject/main.libsonnet';
local deployment = import '../k8s/libs/deployment.libsonnet';
local service = import '../k8s/libs/service.libsonnet';
local ingress = import '../k8s/libs/ingress.libsonnet';
local parameters = import './parameters.libsonnet';

// Define features for deployment, service, and ingress
local deploymentFeature = EasyProject.feature(
  name='deployment',
  configs=[
    deployment.simpleDeployment(parameters.bookApp)
  ]
);

local serviceFeature = EasyProject.feature(
  name='service',
  configs=[
    service.NodePort(parameters.bookApp)
  ]
);

local ingressFeature = EasyProject.feature(
  name='ingress',
  configs=[
    ingress.simpleIngress(parameters.bookApp)
  ]
);

// Create an application with these features
local app = EasyProject.app(
  name='book-review-app',
  features=[
    deploymentFeature,
    serviceFeature,
    ingressFeature
  ]
);

// Render the application with parameters
app.render(params=parameters)