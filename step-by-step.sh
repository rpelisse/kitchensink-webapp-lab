#!/bin/bash

readonly CONF_HOME=${CONF_HOME:-'/home/rpelisse/Repositories/contrib/emea-conf/'}
readonly WEBAPP_GITHUB_URL=${WEBAPP_GITHUB_URL:-'https://github.com/rpelisse/kitchensink-webapp-lab.git'}

readonly EAP_DOCKER_IMAGE=${EAP_DOCKER_IMAGE:-'jboss-eap64-openshift'}
readonly JDG_DOCKER_IMAGE=${JDG_DOCKER_IMAGE:-'datagrid65-basic'}

readonly PROJECT_NAME=${1:-'kitchensink-webapp-lab'}
readonly WEBAPP_NAME=${WEBAPP_NAME:-'kitchensink-webapp'}

export PATH=${CONF_HOME}:${PATH}

if [ ! -x $(which oc) ]; then
  echo "'oc' command not in PATH - aborting."
  exit 1
fi

if [ -z "${NO_LOGIN}" ]; then
  oc login
fi

echo 'Step 0 - Create a Project...'
if [ -z "${NO_PROJECT_SETUP}" ]; then
  oc new-project "${PROJECT_NAME}" --description="Kitchen Sink JDG Lab" --display-name="${WEBAPP_NAME}"
fi
echo 'Done.'

echo 'Step 1 - Add JBEAP 6.4 server with the webapp'
if [ -z "${NO_EAP_SETUP}" ]; then
  oc new-app "${EAP_DOCKER_IMAGE}~${WEBAPP_GITHUB_URL}" --name="${WEBAPP_NAME}"
  echo 'Done.'

  echo -n 'Wait 5 minutes for container to be started...'
  sleep 300
  echo 'Done'

  echo 'Step 1.1 - Expose the newly created service...'
  oc expose service ${WEBAPP_NAME}
  # TODO: No healthcheck
  # oc set probe dc/kitchensink-webapp --readiness --get-url=http:///index.jsf  --initial-delay-seconds=60
fi
echo 'Done'

echo 'Step 2 - Add JDG Instance to cache data'
if [ -z "${NO_JDG_SETUP}" ]; then
  oc new-app "${JDG_DOCKER_IMAGE}" --name="jdg-storage"
  echo 'Done.'

  echo 'Enables Kubernetes Ping for clustering...'
  oc policy add-role-to-user view system:serviceaccount:"${PROJECT_NAME}":default -n "${PROJECT_NAME}"
  echo 'Done.'

  echo -n 'Wait 5 minutes for container to be started...'
  sleep 300
  echo 'Done.'

  echo 'List (new) available services:'
  oc get svc
fi

if [ -z "${NO_APP_UPDATE}" ]; then
  echo 'Add required env vars to the webapp envs vars...'
  oc env dc/${WEBAPP_NAME} HOTROD_SERVICE=datagrid-app-hotrod
  oc env dc/${WEBAPP_NAME} HOTROD_SERVICE_PORT=11333
  echo 'Done'

  echo 'Update WebApp to use the JDG cache'
  readonly local_repo=$(mktemp -d)
  git clone "${WEBAPP_GITHUB_URL}" "${local_repo}"
  cd "${local_repo}"
  git push --force origin origin/STEP_1:master
  cd - > /dev/null
  rm -rf "${local_repo}"
  echo 'Done'

  echo 'Start a new build for the webapp...'
  oc start-build "${WEBAPP_NAME}"
  echo 'Done.'
fi
