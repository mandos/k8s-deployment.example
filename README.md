# K8s Deployment (Example)

<a name="table-of-content"></a>
Table of Content:
- [Introduction](#introduction)
- [Local Development Environment](#local-development-environment)
- [Project Structure](#project-structure)
- [Deployment Process and Toolset](#deployment-process-and-toolset)
   * [Deployment Verification](#deployment-verification)
- [Build and Using Local Environment](#build-and-using-local-environment)
- [Helmfile Reasoning](#helmfile-reasoning)
- [Architecture](#architecture)
   * [Service Layer Breakdown](#service-layer-breakdown)
- [Application Stack ](#application-stack)
   * [External Services](#external-services)
      + [HashiCorp Vault](#hashicorp-vault)
      + [Reloader](#reloader)
      + [PostgreSQL](#postgresql)
   * [In-House Services](#in-house-services)
      + [DevOps](#devops)
      + [Backend](#backend)
      + [Frontend](#frontend)
- [Secrets Management](#secrets-management)

## Introduction

This project demonstrate the deployment of a simple frontend-backend application in Kubernetes.

The objectives of this project are to:

- Showcase how to use a local Kubernetes environment for development and testing.
- Introduce tools for deploying a full-stack application and its dependent services to Kubernetes.
- Explore different approaches to managing secrets in a Kubernetes environment.
- Enhance network security by implementing **Network Policies**

[Back to Table of Content](#table-of-content)

## Local Development Environment

A fast and easily configurable local environment is crucial for implementing a rapid development
process with a quick feedback loop. My current setup is based on [Minikube](https://minikube.sigs.k8s.io/) 
using the [Docker driver](https://minikube.sigs.k8s.io/docs/drivers/docker). This approach allows for easy
testing of different configurations, even when working on multiple projects, thanks to **Minikube
profiles**.

To monitor the state of the Kubernetes cluster, I use [k9s](https://k9scli.io/), which provides 
a user-friendly terminal UI. For scripting and automation tasks, I primarily use 
[kubectl](https://kubernetes.io/docs/reference/kubectl/).

For task automation, I use [just](https://just.systems/). Initially, I used [GNU Make](https://www.gnu.org/software/make/),
but it has its own quirks. *just* aiiows me to create a consistent CLI interface that streamlines interactions
with all project-related tools.

The full list of available commands can be accessed by running:
```sh
    $ just
```
All further command examples will include both the *just* version and the original command. The command
definitions can be found in the [justfile](justfile).

List of tools *(The versions in bracklets indicate the ones used by me during development)*:

- docker engine (v27.3.0)
- minikube (v1.34.0) with Kubernetes (v1.31.0)
- kubectl (v1.31.2) 
- just (1.37.0)
- k9s (0.32.6)

[Back to Table of Content](#table-of-content)

## Project Structure

```
|-- charts
|   |-- backend
|   |-- devops
|   `-- frontend
|-- docker
|   `-- backend-verification
|-- environments
|   |-- development
|   |   `-- secrets
|   `-- common.yaml
|-- sops
|-- vault
|-- .sops.yaml
|-- helmfile.yaml
|-- justfile
```

Explanation:

- *charts/* – Contains custom Helm charts for:
  * DevOps configuration
  * Frontend application
  * Backend application
- *docker/backend-verification/* – Includes all files needed to build an image for verifying whether the backend service is functioning correctly.
- *environments/* – Stores environment-specific variables and secrets used as input for Helm releases.
  * *development/secrets/* – Secrets specific to the development environment.
  * *common.yaml* – Shared configuration across environments.
- *sops/* – Contains GPG keys.
- *vault/* – Contains the initial configuration for HashiCorp Vault, used in the `just init-vault` task.
- *.sops.yaml* – Configuration file for SOPS (Secrets OPerationS).
- *helmfile.yaml* – The main configuration file for Helmfile, defining how Helm releases are managed.
- *justfile* – Contains just task definitions for automating common project tasks.

[Back to Table of Content](#table-of-content)

## Deployment Process and Toolset

To configure the cluster and deploy all necessary applications, I chose a **push-based approach**. 
This method is easier and faster to run locally, as it doesn't require additional services like 
[ArgoCD](https://argo-cd.readthedocs.io/) or [FluxCD](https://fluxcd.io/) within Kubernetes.

Two main tools in this process are (Helm)[https://helm.sh/] to manage installation of separate application and
[Helmfile](https://helmfile.readthedocs.io/) to manage full stack and environments. I could use Helm alone 
but *Helmfile* allows me to better manage variables (per environment), secrets and installing/updating not 
only full stack but some part's of it. More info about it will be in section [Application Stack](#application-stack)


The two main tools in this process are:

- [Helm](https://helm.sh/) – Manages the installation of individual applications.
- [Helmfile](https://helmfile.readthedocs.io/) – Manages the entire stack and different environments.

While I could use Helm alone, Helmfile provides better control over environment-specific 
variables, secrets, and selective stack deployments (not just full-stack updates). More 
details can be found in the [Application Stack](#application-stack) section.

For secrets manament, I'm using:

- [SOPS](https://github.com/getsops/sops)
- [The GNU Privacy Guard](https://www.gnupg.org/)

More details on secrets management are covered in the [Secrets Management](#secrets-management) section.

List of tools *(The versions in bracklets indicate the ones used by me during development)*:

- helmfile (v0.169.0)
- helm (v3.16.3)
- helm plugins:
  * diff (3.9.13)
  * secrets (4.6.0)
- GnuPG (2.4.5)

### Deployment Verification

To verify whether deployments have been successfully completed, I use a combination of built-in Helm mechanisms and Kubernetes configuration:

- **Helm Timeouts and Atomic Updates** – Ensures deployments are rolled back if they fail, and prevents timeouts during updates.
- **Kubernetes Rollout Policies** – Manages deployment strategies, ensuring the smooth rollout of new versions and handling failures appropriately.
- **Kubernetes Liveness and Readiness Checks** – Helps Kubernetes determine whether a service is healthy and ready to serve traffic.
- **Helm Test Feature** – Runs tests to validate the deployment once it’s finished, ensuring everything is working as expected.

More information about testing the backend release can be found in section [Application Stack -> In-House Services -> Backend](#backend)

[Back to Table of Content](#table-of-content)

## Build and Using Local Environment

Setting up the local environment involves multiple tools, making the process somewhat complex. 
I personally use [NixOS](https://nixos.org/) with [Home Manager](https://nix-community.github.io/home-manager/) to manage this toolset.
Currently, there is no Nix configuration available for this setup, but it will be added in the future:<br>
👉 [Add Nix setup with tools for local environment](https://github.com/mandos/k8s-deployment.example/issues/1)

If you’re not using NixOS, another option is to install Minikube and Docker Engine manually and
use a pre-built image containing all necessary tools (planned feature):<br>
👉 [Create image with full toolset](https://github.com/mandos/k8s-deployment.example/issues/2)

Once all required tools are installed, the local environment can be set up with the following steps:

1. Create a Minikube Cluster: `just create-k8s`<br>
   This creates a 3-node Kubernetes clster (v1.31.0) with Calico CNI, Nginx Ingress Controller and CSI Plugin. 
   Each node is allocated 2 CPUs and 3072 MB RAM.  
2. Initialize Helmfile: `just init-helmfile`<br> 
   Check Helmfile settings and installs neccessary Helm plugins.
3. Import GPG Keys: `just import-gpg-keys`<br> 
   One of solution I'm using for secrets management is SOPS with encription using GPG, this is why we need
   add these keys to local keyring. As side notes, these keys are from SOPS project and are used for
   functional testing.
   Sinsce *SOPS* is used for secrets management (with GPG encription), this step adds the requiered GPG keys
   to the local keyring. The provided keys are from the SOPS project and are used for functional testing.
4. Install Core Services: `just install-tier core`<br>
   Installs Kubernetes configuration and supporting services inside the cluster.
5. Configure HashiCorp Vault: `just init-vault`<br> 
   Sets up HashiCorp Vault with the required configuration for secret management.

Instead of running these commands separately, a single command can be used to execute all steps: `just create-environment`.

After setting up the environment, applications can be installed with:
```sh
  just install-app app1
  just install-app app2
  just install-tier apps
```
At this point, the local environment is fully configured and ready for use.

Shutting down the environment can be done with: `just stop-k8s`. It can be restarted later with: `just start k8s`.
Destroying local environment is done with: `just destroy-k8s`.

**Important note**: Since *HashiCorp Vault* is running in dev mode, there is no persistent storage. 
This means that every time the environment is restarted, Vault must be reconfigured using: `just init-vault`

This issue is planned to be fixed in:<br>
👉 [Add persistance storage to Vault](https://github.com/mandos/k8s-deployment.example/issues/3)

[Back to Table of Content](#table-of-content)

## Helmfile Reasoning

This section describes the main reasoning behind choosing Helmfile as the primary tool for deploying 
the application stack. The goal was to deploy multiple Helm charts, currently nine, including 
both external and in-house charts. The applications depend on each other, require secrets management, 
and need a flexible deployment process that allows full or partial redeployment.

Using raw Helm alone comes with challenges:

- Installing all charts separately leads to dependency issues at the application level and complicates values management
- Using an umbrella chart for the full stack is not scalable, as it always deploys everything at once without an option for partial updates
- A mixed approach, some umbrella charts and some standalone, reduces some issues but does not fully eliminate them

How Helmfile solves these issues:

- **Application dependencies.** The needs key in a release allows defining dependencies between services, 
  ensuring they are installed in the correct order. For example, the frontend depends on the backend, 
  so Helmfile ensures they are deployed accordingly
- **Partial deployment.** Labels enable selective deployment of services. The configuration includes two labels
  *tier* (core and apps) and  *app* (devops, app1, app2, vault, postgresql, reloader). <br>
  This allows deploying specific apps with `just install-app app1` or entire core services with `just install-tier core`
- **Secrets management.** Helmfile seamlessly integrates with the Helm Secrets plugin
- **Environment and values management.** Values files can be structured by environments (development, staging, production), services (backend, frontend) and shared configurations (common.yaml). In this project, only the development environment is used, but the structure supports easy expansion
- **Fine-tuned release configuration.** I can customise specific releases. For example *devops*, *vault*, and *postgresql*, create their own namespaces. *postgresql* and *vault* have longer timeouts to accommodate their setup, etc.

This approach makes deployments more manageable, scalable, and flexible, ensuring efficient development and operations

[Back to Table of Content](#table-of-content)

## Architecture

The solution is built on a few key assumptions:
1. Kubernetes Cluster Provisioning - the Kubernetes cluster is not created by this solution; 
it is provided externally (in the local environment, this is handled by Minikube).
2. Preinstalled Services - some services inside the cluster are already preinstalled, including:
  * CNI Plugin – Calico
  * CSI Plugin
  * Ingress Controller – Nginx
  * CoreDNS
3. Deployment Responsibilities
  * Deployments within Kubernetes can be handled by different teams, including DevOps, Frontend, and Backend teams.
  * This setup provides only a basic structure for team-based deployments. Currently, namespaces are used to separate applications, but roles and role bindings are not yet implemented.

[Back to Table of Content](#table-of-content)

### Service Layer Breakdown

This solution consists of three layers:
- Kubernetes Control Plane & Core Services – Managed by Minikube.
- Core Configuration & Infrastructure Services – Managed by the DevOps team.
- Application Services – Managed by development teams (Frontend & Backend).

```mermaid
flowchart LR 
subgraph "Minikube Layer"
  control-plane[Control Plane]
  cni[Calico CNI]
  dns[CoreDNS]
  csi[Storage Controler]
  ingress[Nginx Ingress Controler]
end

subgraph "Core Services"
  devops[Core DevOps Config]
  db[(Postgresql)]
  subgraph "HashiCorp Vault"
    vault[Vault]
    operator[Vault Secrets Operator] 
  end
end

subgraph "Application Layer"
  direction TB
  subgraph app1
    direction BT 
    app1back[app1-back] --- app1front[app1-front]
  end

  subgraph app2
    direction BT 
    app2back[app2-back] --- app2front[app2-front]
  end
end
```

[Back to Table of Content](#table-of-content)

## Application Stack 

The Application Stack includes all releases managed by Helmfile (see [helmfile.yaml](helmfile.yaml)). This encompasses not only the applications that need to be deployed but also:

- Core services that these applications depend on.
- Generic Kubernetes configurations managed by the DevOps team.

This approach ensures that both application-specific and infrastructure-related components are deployed and maintained in a consistent, automated manner. To have better control, I utilize namespaces. In the current setup, this helps improve network isolation and organization within the cluster.

Namespaces with their purpose: 

- **core** - Contains the DevOps chart release, managing Kubernetes configuration and minor core services (e.g., reloader).
- **database** - PostgreSQL installation
- **vault** - Dedicated to HashiCorp Vault and HashiCorp Secrets Operator.
- **backend** - Namespace for the in-house backend applications.
- **frontend** - Namespace for the in-house frontend applications.

TODO: Add dependency graph

[Back to Table of Content](#table-of-content)

### External Services

#### HashiCorp Vault

As part of secrets management for **app1** application, I implemented a solution based on [HashiCorp Vault](https://developer.hashicorp.com/vault/docs?product_intent=vault). This installation is minimal, and for simplicity, I am currently using dev mode, which requires reconfiguring Vault every time the Local Dev Environment is started.

In this setup, the following Vault features are used:

- [Key/Value v2 secret engine](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2) – Stores secrets, such as database credentials.
- [Kubernetes auth method](https://developer.hashicorp.com/vault/docs/auth/kubernetes) – Allows Kubernetes to authenticate with Vault and update secrets.
- [Transit secret engine](https://developer.hashicorp.com/vault/docs/secrets/transit)– Provides encryption for Vault Secrets Operator.

Additionally, Vault Secrets Operator is installed as a complementary service. This enables automatic updates of Kubernetes secrets and, if necessary, triggers deployment rollouts.

TODO:
👉 [Add persistance storage to Vault](https://github.com/mandos/k8s-deployment.example/issues/3)

#### Reloader

[Reloader](https://github.com/stakater/Reloader) is required as part of the SOPS-based secrets management solution for **app2**. This lightweight service automatically triggers deployment rollouts whenever *ConfigMaps* or *Secrets* change.

While I could also use Reloader for **app1**, I intentionally kept the secrets management solutions separate to maintain clear boundaries between different approaches.

#### PostgreSQL

A non-HA, basic PostgreSQL installation is used, based on the [Bitnami PostgreSQL Helm chart](https://artifacthub.io/packages/helm/bitnami/postgresql). The setup mostly relies on default values, with minimal modifications, primarily storing the master password in a SOPS-encrypted YAML file for security.

TODO:
👉 [Hardening network policies for Postgresql](https://github.com/mandos/k8s-deployment.example/issues/5)

[Back to Table of Content](#table-of-content)

### In-House Services

All charts are created following the [YAGNI principle](https://en.wikipedia.org/wiki/You_aren't_gonna_need_it) to keep them minimal and focused.

- The DevOps chart was built from scratch.
- The Backend and Frontend charts were initially generated using helm create and then customized as needed.
- [JSONSchema validation](https://helm.sh/docs/faq/changes_since_helm2/#validating-chart-values-with-jsonschema) has not been added yet, but if the number of input values increases, it will be the preferred way to prevent common misconfigurations.

#### DevOps

This is an example of a basic configuration for a cluster where different teams can deploy and manage their own applications. Due to namespace separation, we can configure settings for different teams or application types. In the current version of the chart, I manage the following:

- **Namespaces** for the database, backend, and frontend applications.
- **Limit Ranges** for the backend and frontend to enforce resource usage limits.
- **Network Separation** between the database, backend, and frontend namespaces to ensure better isolation.
- Preparation of **Secrets** containing database parameters for the app2 backend application (part of SOPS secrets management).

TODO: 
👉 [Add Network separation by egress for namespaces](https://github.com/mandos/k8s-deployment.example/issues/4)

#### Backend

#### Frontend


[Back to Table of Content](#table-of-content)

## Secrets Management

TODO

[Back to Table of Content](#table-of-content)

