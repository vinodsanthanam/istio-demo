JAEGER_POD_NAME=$(shell kubectl -n istio-system get pod -l app=jaeger -o jsonpath='{.items[0].metadata.name}')
SERVICEGRAPH_POD_NAME=$(shell kubectl -n istio-system get pod -l app=servicegraph -o jsonpath='{.items[0].metadata.name}')
GRAFANA_POD_NAME=$(shell kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}')
PROMETHEUS_POD_NAME=$(shell kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}')
TELEMETRY_POD_NAME=$(shell kubectl -n istio-system get pod -l app=telemetry -o jsonpath='{.items[0].metadata.name}')

IMAGE_NAME=gcr.io/${PROJECT_ID}/vinodsanthanam/api:v6

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

wait:
	sleep 3

ingress:
	istioctl kube-inject -f istio/ingress.yaml | kubectl apply -f -

egress:
	istioctl kube-inject -f istio/egress.yaml | kubectl apply -f -

routing:
	istioctl kube-inject -f istio/routing.yaml | kubectl apply -f -

routing-with-retries:
	istioctl kube-inject -f istio/routing-with-retries.yaml | kubectl apply -f -

rules:	
	istioctl kube-inject -f istio/destination-rules.yaml | kubectl apply -f -

telemetry:
	istioctl kube-inject -f istio/telemetry.yaml | kubectl apply -f -

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

build:
  	docker build -t vinodsanthanam/api:v6 .

deploy:
	istioctl kube-inject -f istio/deployment.yaml | kubectl apply -f -
	istioctl kube-inject -f istio/services.yaml | kubectl apply -f -

canary:
	istioctl kube-inject -f istio/canary.yaml | kubectl apply -f -

inject-fault:
	istioctl kube-inject -f istio/fault-injection.yaml | kubectl apply -f -	

circuit-breaker:
	istioctl kube-inject -f istio/circuit-breaker.yaml | kubectl apply -f -	

setup: build clean-all deploy ingress routing rules telemetry ls

setupgcloud: build2gcloud push2gcloud deploy2gcloud ingress routing rules

reset: setup

enable-egress: egress

start-monitoring:
	@echo "Jaeger on port 16686"
	@echo "Service Graph on port 8088"
	@echo "Grafana on port 3000"
	@echo "Prometheus on port 9090"
	@echo "Telemetry on port 9093"
	@sleep 2
	$(shell kubectl -n istio-system port-forward $(JAEGER_POD_NAME) 16686:16686 & kubectl -n istio-system port-forward $(SERVICEGRAPH_POD_NAME) 8088:8088 & kubectl -n istio-system port-forward $(GRAFANA_POD_NAME) 3000:3000 & kubectl -n istio-system port-forward $(PROMETHEUS_POD_NAME) 9090:9090 & kubectl -n istio-system port-forward $(TELEMETRY_POD_NAME) 9093:9093)

ls:
	kubectl get deployments -o wide
	kubectl get pods -n istio-system
	sleep 3
	watch -n20 kubectl get pods -o wide --show-labels

lspods:
	watch -n3 kubectl get pods -o wide

lsipods:
	watch -n3 kubectl get pods -n istio-system

loadtest:
	fortio load -n 20 -c 3 http://192.168.99.100:31380/	

test:
ifdef chk
	@echo $(chk)
	@echo ${PATH}
else
	@echo "Not Defined"
endif
