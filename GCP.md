# GCP

> Dibuat untuk memudahkan DevOps dalam melakukan deployment ke GCP

## Commands

```bash
### LOGIN ###
gcloud auth login
gcloud container clusters get-credentials gke-secure-onboarding-system --zone asia-southeast1-a --project model-parsec-465503-p3


##### BACKEND & Database #####
kubectl apply -f backend-configmap.yaml -n backend
kubectl apply -f backend-deployment.yaml -n backend

kubectl delete -f backend-deployment.yaml -n backend

kubectl rollout restart deployment/backend-deployment -n backend       
kubectl delete replicaset.apps/backend-deployment-76489489b6 -n backend  
kubectl rollout restart deployment/frontend-deployment -n frontend

kubectl exec -it -n backend postgresql-0 -- psql -U database -d customer-registration


# eksekusi ke dalam pods postgresql utk verifikasi sudah ada
kubectl exec -it -n backend postgresql-0 -- psql -U database -d customer-registration

##### FRONTEND #####

# hapus & apply ulang deployment frontend
kubectl delete -f .\frontend-deployment.yaml -n frontend
kubectl delete -f .\frontend-service.yaml -n frontend
kubectl delete -f .\ingress.yaml -n frontend         

kubectl apply -f .\frontend-deployment.yaml -n frontend
kubectl apply -f .\frontend-service.yaml -n frontend
kubectl apply -f .\ingress.yaml -n frontend         

kubectl get pods -n frontend

# melihat IP dari service frontend
kubectl get service frontend-service -n frontend

# melihat detail dari frontend-service
kubectl describe service frontend-service -n frontend

# melihat ingress yang ada (di namespace frontend)
kubectl get ingress -n frontend

# melihat detail dari ingress
kubectl describe ingress secure-onboarding-ingress -n frontend
```
```bash
### Jenkins Password ###
kubectl exec -it -n jenkins jenkins-master-0 -- cat /var/jenkins_home/secrets/initialAdminPassword
b40ab7d471da474db4e1892845bbcde0
```

```bash
kubectl apply -f alert-deployment.yaml -n monitoring
kubectl apply -f alert-rules.yaml -n monitoring
kubectl apply -f alertmanager.yaml -n monitoring
kubectl apply -f grafana-configmap.yaml -n monitoring
kubectl apply -f grafana-service.yaml -n monitoring
kubectl apply -f grafana-statefulset.yaml -n monitoring
kubectl apply -f ingress.yaml -n monitoring
kubectl apply -f monitoring-certificate.yaml -n monitoring
kubectl apply -f prome-configmap.yaml -n monitoring
kubectl apply -f prome-daemonset.yaml -n monitoring
kubectl apply -f prome-service.yaml -n monitoring

kubectl delete -f alert-deployment.yaml -n monitoring
kubectl delete -f alert-rules.yaml -n monitoring
kubectl delete -f alertmanager.yaml -n monitoring
kubectl delete -f grafana-configmap.yaml -n monitoring
kubectl delete -f grafana-service.yaml -n monitoring
kubectl delete -f grafana-statefulset.yaml -n monitoring
kubectl delete -f ingress.yaml -n monitoring
kubectl delete -f monitoring-certificate.yaml -n monitoring
kubectl delete -f prome-configmap.yaml -n monitoring
kubectl delete -f prome-daemonset.yaml -n monitoring
kubectl delete -f prome-service.yaml -n monitoring

kubectl edit servicenetworkendpointgroup k8s1-3963eb42-monitoring-prometheus-9090-03626dab -n monitoring