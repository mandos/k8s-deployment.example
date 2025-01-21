.PHONY: verify init run install

verify-dependencies:
	echo "Checking if all dependencies exists..."
	command -v helmfile
	command -v minikube
	command -v docker
	echo "Everything is ok."

init: verify-dependencies
	helmfile init
 
start-k8s: verify-dependencies
	minikube start --profile=vin --nodes=3  --cni=calico --addons=storage-provisioner
		

stop-k8s:
	minikube stop --profile=vin 

install: 
	helmfile sync --selector type=app --environment=development

