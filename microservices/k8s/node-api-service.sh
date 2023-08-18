
kubectl expose deployment node-api-app --name node-api-svc \
    --type NodePort --protocol TCP --port 8081 --target-port 8081

# this works on GKE
# kubectl expose deployment node-api-app --name node-api-lb-svc \
#    --type LoadBalancer --port 60000 --target-port 8080
