docker tag hono-app omezh/hono-app:latest
docker push omezh/hono-app:latest


kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml


kubectl get pods
kubectl get services


kubectl port-forward service/hono-app-service 3000:80
