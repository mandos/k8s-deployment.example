environment := env('ENVIRONMENT', 'development')
profile := 'vin-' + environment

# Show lis of all commands
default:
	@just --list

# Checking if all necessary applications are installed
verify-dependencies:
	@echo "Checking if all dependencies exists..."
	command -v helmfile
	command -v minikube
	command -v docker
	command -v gpg
	@echo "Everything looks ok."

# Initialize helmfile (helm plugins)
init-helmfile:
	helmfile init

# Initialize Hashicorp Vault configuration 
init-vault:
	kubectl cp --namespace vault ./vault/init.sh vault-0:/tmp/init.sh
	kubectl exec --namespace vault -i -t vault-0 -c vault -- /tmp/init.sh

# Generate temmporary folder
_make-tmp-dir:
	mkdir -p vendors

# Import functional test GPG keys from Sope project
import-gpg-keys: _make-tmp-dir
	-git clone --depth=1 https://github.com/getsops/sops.git tmp/sops
	gpg --import tmp/sops/pgp/sops_functional_tests_key.asc

# Create k8s cluster and initialize full local environment (with core services)
create-all: verify-dependencies
	just create-k8s
	just import-gpg-keys
	just init-helmfile
	just install-tier core
	just init

# Create Minikube profile with specific addons
create-k8s: verify-dependencies
	minikube start --profile={{profile}} --nodes=3  --cni=calico --addons=csi-hostpath-driver --addons=ingress --kubernetes-version=v1.31.0 --cpus 2 --memory 3072

# Delete Minikube profile
destroy-k8s: verify-dependencies 
	minikube delete --profile={{profile}}
 
# Start Minikube
start-k8s: verify-dependencies
	minikube profile list | grep {{profile}}
	minikube start --profile={{profile}} 
		
# Stop Minikube
stop-k8s:
	minikube stop --profile={{profile}} 

# Show list of services
services:
	minikube service list --profile={{profile}} 

# Install all releases
install-all: 
	helmfile sync --environment={{environment}}

# Install releases of specific tier
install-tier tier-name helmfile-args='':
	helmfile sync --environment={{environment}} --selector tier={{tier-name}} {{helmfile-args}}

# Install releases of specific app
install-app app-name helmfile-args='':
	helmfile sync --environment={{environment}} --selector app={{app-name}} {{helmfile-args}}


# Show diff for all releases
diff:
	helmfile diff --environment={{environment}}

# Show diff for specific tier
diff-tier tier-name:
	helmfile diff --environment={{environment}} --selector tier={{tier-name}}

# Show diff for specific app
diff-app app-name:
	helmfile diff --environment={{environment}} --selector app={{app-name}}

# Test all releases
test:
	helmfile test --environment={{environment}}

# Test single app
test-app app-name:
	helmfile test --environment={{environment}} --selector app={{app-name}}

# Test if ingress for specific application is working
test-ingress app-name path='':
	curl --resolve "{{app-name}}-front.vin-{{environment}}.minikube:80:$( minikube ip --profile {{profile}})" -i http://{{app-name}}-front.vin-{{environment}}.minikube/{{path}}

# Build image to verify backend
build-backend-verification tag:
	docker build -f ./docker/backend-verification/Dockerfile -t mandos22/assessment-back-test:"{{tag}}"  ./docker/backend-verification

# Push to Dockerhubverify backend image
build-push-backend-verification tag: (build-backend-verification tag)
	docker push mandos22/assessment-back-test:"{{tag}}"

