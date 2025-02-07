# K8s Deployment (Example)

<a name="table-of-content"></a>
Table of Content:
- [Introduction](#introduction)
- [Local Development Environment](#local-development-environment)
- [Project Structure](#project-structure)
- [Deployment Process and Toolset](#deployment-process-and-toolset)
- [Architecture](#architecture)
   * [Service Layer Breakdown](#service-layer-breakdown)
- [Application Stack ](#application-stack)
   * [Helmfile ](#helmfile)
   * [Services](#services)
- [Secrets Management](#secrets-management)
- [Create local environment](#create-local-environment)
- [TODO](#todo)

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

This approach ensures that both application-specific and infrastructure-related components are deployed and maintained in a consistent, automated manner.

[Back to Table of Content](#table-of-content)

### Helmfile 

[Back to Table of Content](#table-of-content)

### Services

This section describes the currently installed services and their purposes.

[Back to Table of Content](#table-of-content)

## Secrets Management

[Back to Table of Content](#table-of-content)

## TODO

- [ ] Write documentation
- [ ] Add separation namespaces egress policies
- [ ] Hardening network policies for Postgresql 

[Back to Table of Content](#table-of-content)
