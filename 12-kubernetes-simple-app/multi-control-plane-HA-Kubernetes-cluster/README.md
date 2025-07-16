minikube --ha --driver=docker --container-runtaime=containerd --profile=-ha-demo


Cluster
 └── Nodes (machines)
      └── Pods (app units)
           └── Containers (like Docker)

So:

A cluster has multiple nodes

A node can run multiple Pods

A Pod runs 1 or more containers

