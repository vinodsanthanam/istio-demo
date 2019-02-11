setup:
	@echo "Follow setup instructions @ https://cloud.google.com/istio/docs/istio-on-gke/installing"
	@echo "Enable API for the project https://istio.io/docs/setup/kubernetes/quick-start-gke-dm/"
	gcloud container clusters get-credentials istio-cluster
	kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value core/account)