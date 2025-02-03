# Show lis of all commands
default:
    @just --list

# Checking if all necessary applications are installed
verify-dependencies:
	@echo "Checking if all dependencies exists..."
	command -v helmfile
	command -v minikube
	command -v docker
	@echo "Everything looks ok."

# Initalize all staff
init: verify-dependencies init-vault init-helmfile

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

 
# Start Minikube
start-k8s: verify-dependencies
	minikube start --profile=vin --nodes=3  --cni=calico --addons=csi-hostpath-driver --addons=volumesnapshots
		
# Stop Minikube
stop-k8s:
	minikube stop --profile=vin 

# Install all releases
install-all: 
	helmfile sync --environment=development

# Install releases of specific tier
install-tier tier-name helmfile-args='':
	helmfile sync --environment=development --selector tier={{tier-name}} {{helmfile-args}}

# Install releases of specific app
install-app app-name helmfile-args='':
	helmfile sync --environment=development --selector app={{app-name}} {{helmfile-args}}

# Show diff for all releases
diff:
	helmfile diff --environment=development

# Show diff for specific tier
diff-tier tier-name:
	helmfile diff --environment=development --selector tier={{tier-name}}

# Show diff for specific app
diff-app app-name:
	helmfile diff --environment=development --selector app={{app-name}}

# Test all releases
test:
	helmfile test --environment=development

# Test single app
test-app app-name:
	helmfile test --environment=development --selector app={{app-name}}

# Build image to verify backend
build-backend-verification tag:
	docker build -f ./docker/backend-verification/Dockerfile -t mandos22/assessment-back-test:"{{tag}}"  ./docker/backend-verification

# Push to Dockerhubverify backend image
build-push-backend-verification tag: (build-backend-verification tag)
	docker push mandos22/assessment-back-test:"{{tag}}"
