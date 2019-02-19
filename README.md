This is a demo app for toying with Istio, tested with Istio Version 1.0.5, Kubernetes v1.13.2

## Prerequisites
* The setup instructions assumes you use Mac OS, if you use any other OS, please follow instructions for the appropriate platform
* Basic working knowledge of [Docker](https://docs.docker.com/engine/docker-overview/), [Kubernetes](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/), [K8 object model](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/).
* If you have upgraded Mac OS to Mojave, please clear your minikube folder (rm -rf ~/.minikube), reinstall latest version of virtual box (if you are using Virtual Box as the hypervisor) and follow the below instructions
* We will be using docker as the container runtime, install docker if you have not already installed from [here](https://runnable.com/docker/install-docker-on-macos)
* Follow the instructions over [here](https://kubernetes.io/docs/tasks/tools/install-minikube/) to install Hypervisor, Kubectl, Minikube
* Virtual Box is a Hypervisor which can be installed from [here](https://www.virtualbox.org/wiki/Downloads)
* Before you start minikube, minikube needs sufficient resources to be able to run istio in the local box.

        > minikube start --memory=8192 --cpus=4
        > minikube start --memory=16384 --cpus=4 (if you have better RAM capacity)

* As you start building your docker images, instead of using local docker context or docker hub for hosting the docker images, it is much faster to use the docker context of minikube to host the images. Run the following command to set the docker context to minikube

        > eval $(minikube docker-env)

	* In case you are working between minikube and cloud provider like GKE, you would have to switch the docker context between your local minikube host and the remote host.
		* The make file as part of the codebase has a target which helps you toggle context between minikube and gcloud
                
                > make toggle_kube_context

* If you are planning to use the Make commands in the project folder, please install [watch](http://osxdaily.com/2010/08/22/install-watch-command-on-os-x/). Watch helps execute commands repetitively every n seconds.
		
        > "brew install watch"

## Setup Istio in your local kubernetes cluster
* Download and extract istio on to your local disk from [here](https://istio.io/about/notes/1.0.5/). The below source code is tested with version 1.0.5
* start minikube from your terminal if you have not started it already, make sure you set the context for docker to minikube before starting (if you dont want to be hassled to set it up every time, add it to your bashprofile while you are working on the demo, and remove it after you are done with the excercise as it can slow down your terminal startup)
		
        > minikube start --memory=16384 --cpus=4

	* once minikube is started, you can check your local k8 cluster by typing the following command on your terminal

                > minikube dashboard

* Once you have started minikube, cd to the istio folder you had just extracted and execute the following commands
		
        > kubectl apply -f install/kubernetes/helm/istio/templates/crds.yaml
        > kubectl apply -f install/kubernetes/istio-demo-auth.yaml

	* The above commands sets up the custom resource definitions and istio in your local kubernetes cluster (If you would like to setup Istio in GKE, you would have to switch to gcloud context, which is covered in the next tutorial)

## Troubleshooting Istio Setup
* You can follow the instructions over [here](https://istio.io/help/ops/) for troubleshooting issues when dealing with Istio
* Execute the following command to list all the istio components running in your local kube cluster
		
        > kubectl get pods -n istio-system -o wide --show-labels (or)
        > make lsipods

	* You may notice that some of the components are running, some may be just initializing, restarting or errored out. In case any of the pods are not starting you can check the log for each of the application to debug. In some cases i.e pilot which is one of the istio [component](https://istio.io/docs/concepts/what-is-istio/) may not start if you had not started Istio with enough resources.
	* You can view the logs in each of pods running the following command

                > kubectl -n istio-system logs $(kubectl -n istio-system get pod -l app=telemetry -o jsonpath='{.items[0].metadata.name}') -c mixer

| Parameter | Description |
| :------------- | :------------- |
| -n istio-system      | -n is to specify the namespace in which the pods are executing, in this case its the istio's namespace |
| app      | is the name of the app we want to check the logs for      |
| jsonpath | is more like XPATH for json      |
| -c | Identifies the container in the pod, you can identify the container name by executing "kubectl get deployments -n istio-system -o wide --show-labels" |
| $(kubectl -n istio-system get pod -l app=telemetry -o jsonpath='{.items[0].metadata.name}') | Helps identify the name of the pod, you can also get it by executing "kubectl get pods -n istio-system -o wide --show-labels" |

## Remove Istio from your local kubernetes cluster
* Start minikube, cd to the istio folder you had extraced. Execute the following commands to remove istio and all the customer resource definitions you had previously installed.
		
        > kubectl delete -f install/kubernetes/istio-demo-auth.yaml
        > kubectl delete -f install/kubernetes/helm/istio/templates/crds.yaml -n istio-system

## How to view Istio Components
* You can view the components running in your Istio Cluster using kubectl port forwarding feature. Istio by default does not allow incoming connections unless you setup appropriate ingress. Few of the default components which gets installed with Istio and default port-forwarding commands (replace the $() with the pod name)

| Component | Port Forward | localhost URL |
| :------------- | :------------- | :------------- |
| Jaeger | kubectl -n istio-system port-forward $(JAEGER_POD_NAME) 16686:16686 | [local jaeger](http://localhost:16686) |
| Prometheus | kubectl -n istio-system port-forward $(PROMETHEUS_POD_NAME) 9090:9090 | [local prometheus](http://localhost:9090/graph?g0.range_input=1h&g0.expr=grpc_server_handled_total&g0.tab=1) |
| Grafana | kubectl -n istio-system port-forward $(GRAFANA_POD_NAME) 3000:3000 | [local grafana](http://localhost:9092/d/1/istio-mesh-dashboard?refresh=5s&orgId=1) |
| Metrics | kubectl -n istio-system port-forward $(TELEMETRY_POD_NAME) 9093:9093 | [local metrics](http://localhost:9093/metrics) |
| Service Graph | kubectl -n istio-system port-forward $(SERVICEGRAPH_POD_NAME) 8088:8088 | [local graph](http://localhost:8088/force/forcegraph.html) |

or you can use the make monitor command as shortcut for port forwarding
		
                > make monitor-jaeger
                > make monitor-prometheus
                ...

## Make shortcuts
> make $command

| Command | Description |
| :------------- | :------------- |
| clean-all      | Removes all the deployments, virtual services, destination rules, services, pods, gateway and service entries |
| clean | Removes installed deployments and services |
| setup | builds docker image, cleans-all, deploys the app, sets up ingress, routing and destination rules, adds telemetry metrics and looks up running instances of the pods |
| reset | is basically pseudo target for setup |
| build | builds docker image |
| deploy | deploys the images and creates the corresponding services |
| ingress | sets up the incoming ingress gateway |
| routing | sets up the routing logic from gateway to pods |
| rules | sets up the load balancing policies for the services |
| egress | sets up the service entry for communication outside of the mesh |
| deploy-failures | Deploys the code to service-c, Please modify the code to add failures |
| retries | Updates the retries policies for the service under test |
| canary | Deploys the canary version of the service and sets up partial redirection of the requests |
| inject-fault | Injects faults in to the environment for the service |


Utility Commands

| Command | Description |
| :------------- | :------------- |
| ls | displays all running deployments and pods |
| lspods | displays all running pods with additional information |
| lsipods | displays all running pods in istio-system namespace |
| loadtest | Runs the fortio loadtest, assumes you have fortio in the path |
| getip | gets the ip address of minikube |
| toggle_kube_context | Toggles kube context between minikube and gcloud |
| show-all-containers | displays all the deployments and the container information |
| scale-containers-for-service-c | Scales the container images to 5 for service c |



## Deploying to GKE

Create your GCP Account and follow instructions [over here](https://istio.io/docs/setup/kubernetes/platform-setup/gke/) to setup your gcloud credentials
The free account should be more than enough to play with Istio on GKE, Just make sure you create the cluster in your appropriate region, select 1 Node with 4 CPU's.
You can create the cluster from the GKE UI.

<img src="/help/images/gke_cluster_setup.png" width="50%">

Before you begin deploying applications make sure you have switched the local kubectl context to gcloud. You can do this by 

        > kubectl config get-contexts
        The get contexts gets a bunch of contexts associated with your kubectl. Copy the cluster information for your gcloud and then execute the below command to set the context
        > kubectl config use-context $cluster_name

or



        > export PROJECT_ID="$(gcloud config get-value project -q)"



