# 

## Setup local testing enviroments localy 

Requirements (in bracklets versions I used):

* docker engine (v27.3.0)?
* minikube (v1.34.0)
* helmfile (v0.169.0)
* helm (v3.16.3)

```sh
    minikube start --profile=vin --nodes=3  --cni=calico --addons=storage-provisioner
    helmfile init
```

### Clean up testing enviroment

```sh
    minikube deelete --profile=vin
```

## Install or update Helm Release

```sh
helmfile sync
```
