#!/bin/bash
#============================================================
#  Date:         February 22, 2016
#  Script:       send_weekly_stats.bash
#  Version:      01
#  Description:  Sends an email weekly to our subscribed users that gives system level
#                  stats and metadata about uploaded files
#============================================================


if [ -d "/opt/heracles/deploy/scholarsphere/current" ]; then
  cd /opt/heracles/deploy/scholarsphere/current
  RAILS_ENV=production
else
  echo "You appear to be working on a local machine, we'll set for development"
  echo "Please ensure you're calling this script from the Rails root directory"
  RAILS_ENV=development
fi
export RAILS_ENV


RESULTS=`bundle exec rake scholarsphere:deliver_weekly_stats 2>&1`

echo $RESULTS
exit 0;
