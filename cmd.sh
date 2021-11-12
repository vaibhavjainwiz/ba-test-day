#!/bin/sh

for i in {1..4}
#for i in 5
do	
	ns=$(echo "ba-test-day-"${i})

	TMP_FOLDER=tmp/${ns}
	mkdir -p ${TMP_FOLDER}

	oc new-project ${ns}
	
	kubectl apply -f infinispan/infinispan.yaml
	kubectl apply -f kafka/kafka.yaml	
	sed "s|ba-test-day[^ ].|${ns}|g" keycloak/export.json > ${TMP_FOLDER}/kogito-realm.json
	kubectl create configmap keycloak-realm-config --from-file=${TMP_FOLDER}/kogito-realm.json
	kubectl apply -f keycloak/keycloak.yaml


	while [[ $(kubectl get pods -l app=infinispan-pod -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for Infinispan pod" && sleep 1; done
	while [[ $(kubectl get pods -l app.kubernetes.io/name=kafka -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for Kafka pod" && sleep 1; done	
	while [[ $(kubectl get pods -l app=kogito-keycloak -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for Keycloak pod" && sleep 1; done

	kubectl apply -f kogito/kogito-infinispan-infra.yaml
	kubectl apply -f kogito/kogito-kafka-infra.yaml
	kubectl apply -f kogito/kogito-data-index.yaml

	sed "s|ba-test-day[^ ].|${ns}|g" kogito/kogito-mgmt-console.yaml > ${TMP_FOLDER}/kogito-mgmt-console.yaml
	kubectl apply -f ${TMP_FOLDER}/kogito-mgmt-console.yaml


	sed "s|ba-test-day[^ ].|${ns}|g" kogito/kogito-task-console.yaml > ${TMP_FOLDER}/kogito-task-console.yaml	
	kubectl apply -f ${TMP_FOLDER}/kogito-task-console.yaml

	kubectl apply -f kogito/kogito-job-services.yaml
	kubectl apply -f kogito/process-usertasks-timer.yaml

done
