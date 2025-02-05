# K8s Deployment (Example)

## Introduction

This project demonstrate the deployment of a simple frontend-backend application in Kubernetes.

The objectives of this project are to:
* Showcase how to use a local Kubernetes environment for development and testing.
* Introduce tools for deploying a full-stack application and its dependent services to Kubernetes.
* Explore different approaches to managing secrets in a Kubernetes environment.
* Enhance network security by implementing **Network Policies**

## Table of Content

* [Local Development Environment](#local-development-environment)
  * [Requirements](#requirements)
  * [Setup](#setup)
  * [Clean Up Development Environment](#clean-up-development-environment)
* [Deployment Toolset](#deployment-toolset)
* [Application Stack](#application-stack)
* [Secrets Management](#secrets-management)
* [TODO][#todo]

## Local Development Environment

### Requirements
*The versions in bracklets indicate the ones used by me during development*

* docker engine (v27.3.0)
* minikube (v1.34.0)
* kubectl (v1.31.2) 
* helmfile (v0.169.0)
* helm (v3.16.3)
* helm plugins: 
  - diff (3.9.13)
  - secrets (4.6.0)
* GnuPG (2.4.5)
* [optional] just (1.37.0)

### Setup

```sh
    minikube start --profile=vin --nodes=3  --cni=calico --addons=storage-provisioner
    helmfile init
```

### Clean Up Development Environment

```sh
    minikube delete --profile=vin
```

## Deployment Toolset


```sh
    helmfile sync
```

## Application Stack 

## Secrets Management

## TODO

* [ ] Add whitelist with paths
* [ ] Write documentation
* [ ] Fix persistance storage for Vault
* [ ] Add separation network policies for backend, frontend and databases(?) namespaces
* [ ] Hardening network policies for Postgresql
* [x] Add ingress
* [x] Set Network policies
* [x] Add test for communication with DB
* [x] Fix soap setup and add init for gpg key


