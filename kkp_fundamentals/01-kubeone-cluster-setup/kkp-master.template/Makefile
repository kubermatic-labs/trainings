#### copy from https://github.com/kubermatic/community-components/blob/master/helper/kubeone-makefile/Makefile

########## K1 Helper for easy management
K1_CONFIG="."
TF_CONFIG="./tf-infra"    #relative from K1_CONFIG
K1_KUBECONFIG ?= kkp-master-kubeconfig

# from K1_CONFIG location
K1_SSH_KEY="./../../.secrets/id_rsa"
#K1_CRED_FILE="./secrets/credentials.kubermatic.yml"
#K1_CRED_FLAG=-c ${K1_CRED_FILE}
#CLOUD_CREDENTIALS_ENV_FILE="./secret/cloud_env.sh"
#include ${CLOUD_CREDENTIALS_ENV_FILE}
#export
export GOOGLE_CREDENTIALS := $(shell cat ../../.secrets/k8c-cluster-provisioner-sa-key.json)

######### KubeOne
k1-load-env:
	test -d ${K1_CONFIG} && echo "[ok]" && echo "kubeone config folder found "
	cd ${K1_CONFIG} && test -f ${K1_SSH_KEY} && chmod 600 ${K1_SSH_KEY} && ssh-add ${K1_SSH_KEY} && echo "[ok] "|| echo "ssh key permission ..."

k1-tf-init:
	cd ${K1_CONFIG} && cd ${TF_CONFIG} && \
		terraform init

k1-tf-apply: k1-load-env k1-tf-init
	cd ${K1_CONFIG} && cd ${TF_CONFIG} && \
		terraform apply

k1-tf-destroy: k1-load-env
	cd ${K1_CONFIG} && cd ${TF_CONFIG} && \
		terraform destroy

k1-tf-refresh: k1-load-env
	cd ${K1_CONFIG} && cd ${TF_CONFIG} && \
		terraform refresh

k1-tf-output: k1-load-env
	cd ${K1_CONFIG} && cd ${TF_CONFIG} && \
		terraform output

k1-apply:k1-load-env
	cd ${K1_CONFIG} && \
		kubeone ${K1_CRED_FLAG} apply -m kubeone.yaml -t ${TF_CONFIG} --verbose  #--auto-approve
	make k1-apply-md

k1-reset: k1-load-env
	cd ${K1_CONFIG} && \
		kubeone ${K1_CRED_FLAG} reset -m kubeone.yaml -t ${TF_CONFIG}  --verbose

k1-apply-md: k1-load-env k1-kubeconfig
	kubectl apply --kubeconfig ${K1_KUBECONFIG} -f ${K1_CONFIG}/machines

k1-kubeconfig: k1-load-env
	cd ${K1_CONFIG} && \
		kubeone ${K1_CRED_FLAG} kubeconfig -m kubeone.yaml -t ${TF_CONFIG} > ${K1_KUBECONFIG}