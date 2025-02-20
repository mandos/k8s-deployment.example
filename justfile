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

# Import functional test GPG keys from Sope project
import-gpg-keys:
    gpg --import sops/sops_functional_tests_key.asc

_create-users-dir:
    mkdir -p users

# TODO: Try to use [working-directory] just version 1.38 https://just.systems/man/en/working-directory.html?highlight=working#working-directory

# Create certificate for user with specific group and add it to kube config file (with context)
create-user user group: _create-users-dir
    #!/usr/bin/env bash
    set -euxo pipefail
    cd users
    user="{{ profile }}-{{ user }}"
    openssl genrsa -out ${user}.key 4096
    openssl req -new -key ${user}.key -out ${user}.csr -subj "/CN={{ user }} /O={{ group }}"
    openssl x509 -req -in ${user}.csr -CA ~/.minikube/ca.crt -CAkey ~/.minikube/ca.key -out ${user}.crt -days 3650
    kubectl config set-credentials ${user} --client-certificate="$(pwd)/${user}.crt" --client-key="$(pwd)/${user}.key"
    kubectl config set-context ${user} --user="${user}" --cluster="{{ profile }}"

# Remove user's data (user, context) from kube config
delete-user user:
    #!/usr/bin/env bash
    set -euxo pipefail
    user="{{ profile }}-{{ user }}"
    kubectl config delete-context ${user}
    kubectl config delete-user ${user}

# Create k8s cluster and initialize full local environment (with core services)
create-environment: verify-dependencies
    just create-k8s
    just --one create-user jules backend-team
    just --one create-user vincent frontend-team
    just --one create-user lance support-team
    just --one create-user winston admin-team
    just init-helmfile
    just import-gpg-keys
    just install-tier core
    just init-vault

# Create Minikube profile with specific addons
create-k8s: verify-dependencies
    minikube start --profile={{ profile }} --nodes=3  --cni=calico --addons=csi-hostpath-driver --addons=ingress --kubernetes-version=v1.31.0 --cpus 2 --memory 3072

# Delete Minikube profile
destroy-k8s: verify-dependencies
    minikube delete --profile={{ profile }}

# Start Minikube
start-k8s: verify-dependencies
    minikube profile list | grep {{ profile }}
    minikube start --profile={{ profile }} 

# Stop Minikube
stop-k8s:
    minikube stop --profile={{ profile }} 

# Show list of services
services:
    minikube service list --profile={{ profile }} 

# Install all releases
install-all:
    helmfile sync --environment={{ environment }}

# Install releases of specific tier
install-tier tier-name helmfile-args='':
    helmfile sync --environment={{ environment }} --selector tier={{ tier-name }} {{ helmfile-args }} --include-transitive-needs

# Install releases of specific app
install-app app-name helmfile-args='':
    helmfile sync --environment={{ environment }} --selector app={{ app-name }} {{ helmfile-args }} --include-transitive-needs

# Show diff for all releases
diff:
    helmfile diff --environment={{ environment }}

# Show diff for specific tier
diff-tier tier-name:
    helmfile diff --environment={{ environment }} --selector tier={{ tier-name }}

# Show diff for specific app
diff-app app-name:
    helmfile diff --environment={{ environment }} --selector app={{ app-name }}

# Test all releases
test:
    helmfile test --environment={{ environment }}

# Test single app
test-app app-name:
    helmfile test --environment={{ environment }} --selector app={{ app-name }}

# Test if ingress for specific application is working
test-ingress app-name path='':
    curl --resolve "{{ app-name }}-front.vin-{{ environment }}.minikube:80:$( minikube ip --profile {{ profile }})" -i http://{{ app-name }}-front.vin-{{ environment }}.minikube/{{ path }}

# Build image to verify backend
build-backend-verification tag:
    docker build -f ./docker/backend-verification/Dockerfile -t mandos22/assessment-back-test:"{{ tag }}"  ./docker/backend-verification

# Push to Dockerhubverify backend image
build-push-backend-verification tag: (build-backend-verification tag)
    docker push mandos22/assessment-back-test:"{{ tag }}"
