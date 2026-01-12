
docker build -t api .

kustomize build --enable-helm . | kubectl apply -f -

kubectl exec -it postgresql-0 -n blazing -- psql -U admin -c "CREATE DATABASE blazing;"

kubectl exec -it postgresql-0 -n blazing -- psql -U admin -l

kubectl rollout restart deployment api-deployment -n blazing

kubectl -n blazing port-forward services/api-service 8080:80

docker push juandago/api:latest



---
2. Borrar el despliegue (Eliminar los pods)
Si ya terminaste tu prueba y quieres que desaparezcan de la lista de docker ps y kubectl get pods:

Bash

# Borra la API y el Servicio
kubectl delete deployment api-deployment -n blazing
kubectl delete service api-service -n blazing

# Borra la base de datos
kubectl delete statefulset postgresql -n blazing