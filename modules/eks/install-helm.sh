
rm -rf ~/.kube/kloia
aws eks --region $REGION update-kubeconfig --name $CLUSTER --kubeconfig ~/.kube/kloia --profile kloia
export KUBECONFIG=~/.kube/kloia


kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller
