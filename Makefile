JAEGER_POD_NAME=$(shell kubectl -n istio-system get pod -l app=jaeger -o jsonpath='{.items[0].metadata.name}')
SERVICEGRAPH_POD_NAME=$(shell kubectl -n istio-system get pod -l app=servicegraph -o jsonpath='{.items[0].metadata.name}')
GRAFANA_POD_NAME=$(shell kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}')
PROMETHEUS_POD_NAME=$(shell kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}')
TELEMETRY_POD_NAME=$(shell kubectl -n istio-system get pod -l app=telemetry -o jsonpath='{.items[0].metadata.name}')

IMAGE_NAME=gcr.io/${PROJECT_ID}/istiodemo/api:v6

clean-all:
	kubectl delete svc --all
	kubectl delete deployment --all
	kubectl delete VirtualService --all
	kubectl delete DestinationRule --all
	kubectl delete Gateway --all
	kubectl delete ServiceEntry --all

clean:
	kubectl delete svc --all
	kubectl delete deployment --all

setup: build clean-all deploy ingress routing rules telemetry ls

setupgcloud: use_gcloud_context rbac2gcloud setuphelm build2gcloud push2gcloud deploy2gcloud ingress routing rules

reset: setup

build:
	docker build -t istiodemo/api:v6 .

deploy:
	istioctl kube-inject -f istio/deployment.yaml | kubectl apply -f -
	istioctl kube-inject -f istio/services.yaml | kubectl apply -f -

ingress:
	istioctl kube-inject -f istio/ingress.yaml | kubectl apply -f -

routing:
	istioctl kube-inject -f istio/routing.yaml | kubectl apply -f -

rules:	
	istioctl kube-inject -f istio/destination-rules.yaml | kubectl apply -f -

telemetry:
	istioctl kube-inject -f istio/telemetry.yaml | kubectl apply -f -

enable-egress: egress	

egress:
	istioctl kube-inject -f istio/egress.yaml | kubectl apply -f -

retries:
	docker build -t istiodemo/api:fail .
	istioctl kube-inject -f istio/routing-with-retries.yaml | kubectl apply -f -

canary:
	docker build -t istiodemo/api:canary .
	istioctl kube-inject -f istio/canary.yaml | kubectl apply -f -

inject-fault:
	istioctl kube-inject -f istio/fault-injection.yaml | kubectl apply -f -	

circuit-breaker:
	istioctl kube-inject -f istio/circuit-breaker.yaml | kubectl apply -f -	

# Commands for moving stuff to GKE
setprojectid:
	# "pull project id from GKE and set it as environment variable"
	export PROJECT_ID="$(gcloud config get-value project -q)"

build2gcloud:
	docker build -t $(IMAGE_NAME) .

push2gcloud:
	gcloud auth configure-docker
	docker push $(IMAGE_NAME)

deploy2gcloud:
	istioctl kube-inject -f istio/gcloud/deployment.yaml | kubectl apply -f -
	istioctl kube-inject -f istio/services.yaml | kubectl apply -f -

canary2gcloud:
	istioctl kube-inject -f istio/gcloud/canary.yaml | kubectl apply -f -

rbac2gcloud:
	kubectl create -f istio/rbac-config.yaml


# Utility commands
setuphelm:
	helm init --service-account tiller

start-monitoring:
	$(shell kubectl -n istio-system port-forward $(JAEGER_POD_NAME) 16686:16686 & kubectl -n istio-system port-forward $(SERVICEGRAPH_POD_NAME) 8088:8088 & kubectl -n istio-system port-forward $(GRAFANA_POD_NAME) 3000:3000 & kubectl -n istio-system port-forward $(PROMETHEUS_POD_NAME) 9090:9090 & kubectl -n istio-system port-forward $(TELEMETRY_POD_NAME) 9093:9093)

monitor-jaeger:
	kubectl -n istio-system port-forward $(JAEGER_POD_NAME) 16686:16686

monitor-prometheus:
	kubectl -n istio-system port-forward $(PROMETHEUS_POD_NAME) 9090:9090

monitor-servicegraph:
	kubectl -n istio-system port-forward $(SERVICEGRAPH_POD_NAME) 8088:8088

monitor-grafana:
	kubectl -n istio-system port-forward $(GRAFANA_POD_NAME) 3000:3000

monitor-telemetry:
	kubectl -n istio-system port-forward $(TELEMETRY_POD_NAME) 9093:9093

ls:
	kubectl get deployments -o wide
	kubectl get pods -n istio-system
	sleep 3
	watch -n20 kubectl get pods -o wide --show-labels

lspods:
	watch -n1 kubectl get pods -o wide

lsipods:
	watch -n10 kubectl get pods -n istio-system

loadtest:
	fortio load -n 20 -c 3 http://192.168.99.100:31380/	

getport:
	kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}'

getip:
	minikube ip

show-all-containers:
	kubectl get deployments -n istio-system -o wide

container-image-name:
	kubectl get pod service-c-prod-6f9c56f5b5-hm9c7 -o jsonpath="{..image}"

scale-containers-for-service-c:
	kubectl scale --replicas=3 deployment/service-c-prod

# use the toggle command to switch kubectl context between minikube and gcloud cluster
# change the grep to your cluster name
CLTR=$(shell kubectl config get-contexts | grep cluster | colrm 1 1 | cut -d" " -f13)
CUR_CLTR=$(shell kubectl config current-context)
toggle_kube_context:
	@echo "current context is $(CUR_CLTR)"
	@echo "cluster is $(CLTR)"
ifeq ($(CUR_CLTR), minikube)
	kubectl config use-context $(CLTR)
else
	kubectl config use-context minikube
endif

current_kube_context:
	kubectl config current-context

use_gcloud_context:
	kubectl config use-context $(CLTR)

# Sample make targets to play with
test:
ifdef chk
	@echo $(chk)
	@echo ${PATH}
else
	@echo "Not Defined"
endif
