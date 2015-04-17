#!/bin/sh

if [ ! $(id -ru) -eq 0 ]; then
  echo "You must run this as root."
  exit
fi


# Production sites
LIVESITES="beaconhill|www.beaconhill.edu.hk 
bradbury|www.bradbury.edu.hk 
cwbs|www.cwbs.edu.hk 
esf|www.esf.edu.hk 
glenealy|www.glenealy.edu.hk 
island|www.island.edu.hk 
jcsrs|www.jcsrs.edu.hk 
kgv|enotice.kgv.edu.hk 
kjs|www.kjs.edu.hk 
kennedy|www.kennedy.edu.hk 
ps|www.ps.edu.hk 
qbs|www.qbs.edu.hk 
renaissance|www.renaissance.edu.hk 
shatincollege|www.shatincollege.edu.hk 
sis|www.sis.edu.hk 
sjs|sjs.esf.monilab.net 
wis|www.wis.edu.hk 
demo|demo.esf.monilab.net"

TESTSITES="beaconhill|bhs-testing.esf.edu.hk
bradbury|bs-testing.esf.edu.hk
cwbs|cwbs-testing.esf.edu.hk
esf|esf-testing.esf.edu.hk
glenealy|gs-testing.esf.edu.hk
island|island-testing.esf.edu.hk
jcsrs|jcsrs-testing.esf.edu.hk
kgv|kgv-testing.esf.edu.hk
kjs|kjs-testing.esf.edu.hk
kennedy|ks-testing.esf.edu.hk
ps|ps-testing.esf.edu.hk
qbs|qbs-testing.esf.edu.hk
renaissance|rc-testing.esf.edu.hk
shatincollege|sc-testing.esf.edu.hk
sis|sis-testing.esf.edu.hk
sjs|sjs-testing.esf.edu.hk
wis|wis-testing.esf.edu.hk"

TIMESTAMP="$(date +%Y%m%d%H%M%S)"
export TIMESTAMP

DRUPAL_ROOT="/var/www/html/"

DATABASES_BACKUP_DIR="/home/terry/databases/backup/$TIMESTAMP/"
DATABASES_DEPLOY_DIR="/home/terry/databases/deploy/"

if [ "$HOSTNAME" == "mail5.esfcentre.edu.hk" ]; then
  SITES=$TESTSITES
  echo "========================="
  echo " TESTING SITE MODE"
  echo "========================="
  echo "$SITES" | while read S; do
    FOLDER=$(echo $S | awk -F\| '{print $1}')
    HOST=$(echo $S | awk -F\| '{print $2}')
    URL="http://$HOST"
    echo "$FOLDER : $URL"
    cd "${DRUPAL_ROOT}sites/${FOLDER}/"

    # backup databases first.....
    echo "Backuping $FOLDER school site DB... "
    /bin/mkdir -p $DATABASES_BACKUP_DIR
    DRUSH="/usr/local/zend/bin/php /usr/local/drush/drush.php -r $DRUPAL_ROOT -l $URL"
    $DRUSH sql-dump --result-file=$DATABASES_BACKUP_DIR${FOLDER}.sql
    echo "Backup done. "

    # import database form live site....
    if [ -f ${DATABASES_DEPLOY_DIR}${FOLDER}.sql ]; then
      echo "Importing $FOLDER school site DB from live site... "
      $DRUSH sqlc < ${DATABASES_DEPLOY_DIR}${FOLDER}.sql
      echo "Import done. "
      echo "Clearing cache..."
      $DRUSH cc all
      echo "Clear cache done."
    else
      echo "Database is not existing."
    fi
  done
  echo "done"
else
  SITES=$LIVESITES

  # export databases.
  echo "========================="
  echo " LIVE SITE MODE"
  echo "========================="
  echo "Dumping ESF school sites DB... "
  echo "$SITES" | while read S; do
    FOLDER=$(echo $S | awk -F\| '{print $1}')
    HOST=$(echo $S | awk -F\| '{print $2}')
    URL="http://$HOST"
    echo "$FOLDER : $URL"
    cd "${DRUPAL_ROOT}sites/${FOLDER}/"
    /bin/mkdir -p $DATABASES_DEPLOY_DIR
    DRUSH="/usr/local/zend/bin/php /usr/local/drush/drush.php -r $DRUPAL_ROOT -l $URL"
    $DRUSH sql-dump --result-file=$DATABASES_DEPLOY_DIR${FOLDER}.sql
  done
  echo "done"
fi

