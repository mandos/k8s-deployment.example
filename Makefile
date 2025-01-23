.PHONY: verify init run install

verify-dependencies:
	echo "Checking if all dependencies exists..."
	command -v helmfile
	command -v minikube
	command -v docker
	echo "Everything is ok."

init: verify-dependencies
	helmfile init

init-vault:
	kubectl cp --namespace vault ./vault/init.sh vault-0:/tmp/init.sh
	kubectl exec --namespace vault -i -t vault-0 -c vault -- /tmp/init.sh
 
start-k8s: verify-dependencies
	minikube start --profile=vin --nodes=3  --cni=calico --addons=storage-provisioner
		
stop-k8s:
	minikube stop --profile=vin 

install: 
	helmfile sync --environment=development

install-core:
	helmfile sync --environment=development --selector tier=core

install-devops:
	helmfile sync --environment=development --selector instance=devops

install-app1:
	helmfile sync --environment=development --selector instance=app1

build-backend-verification:
	docker build -f ./docker/backend-verification/Dockerfile -t mandos22/assessment-back-test:"$(tag)"  ./docker/backend-verification

build-push-backend-verification: build-backend-verification
	docker push mandos22/assessment-back-test:"$(tag)"
