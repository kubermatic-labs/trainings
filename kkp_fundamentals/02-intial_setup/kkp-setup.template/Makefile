######### Define deployed version
KKP_VERSION = v2.17.1
KKP_RELEASE_ROOT_FOLDER="./releases"

######### Kubermatic KKP
### Kubermatic configs
KKP_INSTALL_FILES ?= "${KKP_RELEASE_ROOT_FOLDER}/${KKP_VERSION}"
CHARTS ?= ${KKP_INSTALL_FILES}/charts

check-env:
ifndef KKP_VERSION
	bash -c "echo -e 'KKP_VERSION is undefined, kubermatic charts are pointing to the following version:\n' \
		&& grep 'repository.*kubermatic/kubermatic' -C 2 ${CHARTS}/kubermatic/values.yaml \
		; exit 1"
endif

################## Helpers
download-kkp-ee-release:
	mkdir -p ${KKP_RELEASE_ROOT_FOLDER}/${KKP_VERSION}
	wget https://github.com/kubermatic/kubermatic/releases/download/${KKP_VERSION}/kubermatic-ee-${KKP_VERSION}-linux-amd64.tar.gz -O- | tar -xz --directory ${KKP_RELEASE_ROOT_FOLDER}/${KKP_VERSION}/
	rm -rf ${KKP_RELEASE_ROOT_FOLDER}/{KKP_VERSION}/.kube

download-kkp-ce-release:
	mkdir -p ${KKP_RELEASE_ROOT_FOLDER}/${KKP_VERSION}
	wget https://github.com/kubermatic/kubermatic/releases/download/${KKP_VERSION}/kubermatic-ce-${KKP_VERSION}-linux-amd64.tar.gz -O- | tar -xz --directory ${KKP_RELEASE_ROOT_FOLDER}/${KKP_VERSION}/
	rm -rf ${KKP_RELEASE_ROOT_FOLDER}/{KKP_VERSION}/.kube

todos:
	git grep --line-number TODO ./