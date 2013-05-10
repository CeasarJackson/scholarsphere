#!/bin/bash
#
# Currently a stub for jenkins as called from
# https://gamma-ci.dlt.psu.edu/jenkins/job/scholarsphere/configure
#	Build -> Execute Shell Command ==
#	test -x /opt/heracles/deploy_integration.sh && /opt/heracles/deploy_integration.sh
# to run CI testing.

function anywait {
    for pid in "$@"; do
        while kill -0 "$pid"; do
            sleep 0.5
        done
    done
}

HHOME="/opt/heracles"
WORKSPACE="${HHOME}/scholarsphere/scholarsphere-integration"
RESQUE_POOL_PIDFILE="${WORKSPACE}/tmp/pids/resque-pool.pid"

echo hello ss-integration
echo "=-=-=-=-= $0 export RAILS_ENV=integration"
export RAILS_ENV=integration

echo "=-=-=-=-= $0 exit if not ss1test"
[[ $(hostname -s) == "ss1test" ]] || exit 1

echo "=-=-=-=-= $0 source ${HHOME}/.bashrc"
source ${HHOME}/.bashrc

echo "=-=-=-=-= $0 source /etc/profile.d/rvm.sh"
source /etc/profile.d/rvm.sh

echo "=-=-=-=-= $0 cd ${WORKSPACE}"
cd ${WORKSPACE}

echo "=-=-=-=-= $0 source ${WORKSPACE}/.rvmrc"
source ${WORKSPACE}/.rvmrc

echo "=-=-=-=-= $0 cp -f ${HHOME}/config/{database,fedora,solr,hydra-ldap}.yml ${WORKSPACE}/config"
cp -f ${HHOME}/config/{database,fedora,solr,hydra-ldap}.yml ${WORKSPACE}/config

echo "=-=-=-=-= $0 bundle install"
bundle install

echo "=-=-=-=-= $0 passenger-install-apache2-module -a"
passenger-install-apache2-module -a

echo "=-=-=-=-= $0 rake db:drop/create/migrate"
RAILS_ENV=integration bundle exec rake db:drop
RAILS_ENV=integration bundle exec rake db:create
RAILS_ENV=integration bundle exec rake db:migrate

echo "=-=-=-=-= $0 rake fixtures:create/refresh"
RAILS_ENV=integration bundle exec rake scholarsphere:fixtures:generate
RAILS_ENV=integration bundle exec rake scholarsphere:fixtures:refresh

echo "=-=-=-=-= $0 resque-pool restart"
[ -f $RESQUE_POOL_PIDFILE ] && {
    PID=$(cat $RESQUE_POOL_PIDFILE)
    kill -15 $PID && anywait $PID
}
bundle exec resque-pool --daemon --environment integration start

echo "=-=-=-=-= $0 rake scholarsphere:generate_secret"
bundle exec rake scholarsphere:generate_secret

echo "=-=-=-=-= $0 rake scholarsphere:resolrize"
RAILS_ENV=integration bundle exec rake scholarsphere:resolrize

echo "=-=-=-=-= $0 touch ${WORKSPACE}/tmp/restart.txt"
touch ${WORKSPACE}/tmp/restart.txt

echo "=-=-=-=-= $0 curl -s -k -o /dev/null --head https://..."
curl -s -k -o /dev/null --head https://scholarsphere-integration.dlt.psu.edu/

retval=$?

echo "=-=-=-=-= $0 finished $retval"
exit $retval

#
# end
