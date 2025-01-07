local deployment = import '../libs/deployment.libsonnet';
local service = import '../libs/service.libsonnet';
local Ingress = import '../libs/ingress.libsonnet';
local parameters = import './parameters.libsonnet';

{
    'bookApp': {
        deployment: deployment.simpleDeployment(parameters),
        service: service.NodePort(parameters),
    },
}