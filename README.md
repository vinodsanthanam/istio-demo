This is a demo app for toying with Istio, tested with Istio Version 1.0.5

## Prerequisites
* The setup instructions assumes you use Mac OS, if you use any other OS, please follow instructions for the appropriate platform
* If you have upgraded Mac OS to Mojave, please clear your minikube folder (rm -rf ~/.minikube), reinstall latest version of virtual box (if you are using Virtual Box as the hypervisor) and follow the below instructions
* We will be using docker as the container runtime, install docker if you have not already installed from [here](https://runnable.com/docker/install-docker-on-macos)
* Follow the instructions over [here](https://kubernetes.io/docs/tasks/tools/install-minikube/) to install Hypervisor, Kubectl, Minikube
* Virtual Box is a Hypervisor which can be installed from [here](https://www.virtualbox.org/wiki/Downloads)
* Before you start minikube, minikube needs sufficient resources to be able to run istio in the local box.
	* minikube start --memory=8192 --cpus=4
	* minikube start --memory=16384 --cpus=4 (if you have better RAM capacity)
* As you start building your docker images, instead of using local docker context or docker hub for hosting the docker images, it is much faster to use the docker context of minikube to host the images. Run the following command to set the docker context to minikube
	* eval $(minikube docker-env)
	* In case you are working between minikube and cloud provider like GKE, you would have to switch the docker context between your local minikube host and the remote host.
		* The make file as part of the codebase has a target which helps you toggle context between minikube and gcloud
			* make toggle_kube_context
* If you are planning to use the Make commands in the project folder, please install [watch](http://osxdaily.com/2010/08/22/install-watch-command-on-os-x/). Watch helps execute commands repetitively every n seconds.
	* "brew install watch"

## Setup Istio in your local kubernetes cluster
* Download and extract istio on to your local disk from [here](https://istio.io/about/notes/1.0.5/). The below source code is tested with version 1.0.5
* start minikube from your terminal if you have not started it already, make sure you set the context for docker to minikube before starting (if you dont want to be hassled to set it up every time, add it to your bashprofile while you are working on the demo, and remove it after you are done with the excercise as it can slow down your terminal startup)
	* minikube start --memory=16384 --cpus=4
	* once minikube is started, you can check your local k8 cluster by typing the following command on your terminal
		* minikube dashboard
* Once you have started minikube, cd to the istio folder you had just extracted and execute the following commands
	* kubectl apply -f install/kubernetes/helm/istio/templates/crds.yaml
	* kubectl apply -f install/kubernetes/istio-demo-auth.yaml
	* The above commands sets up the custom resource definitions and istio in your local kubernetes cluster (If you would like to setup Istio in GKE, you would have to switch to gcloud context, which is covered in the next tutorial)
* 
