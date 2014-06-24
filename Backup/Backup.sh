#!/bin/bash

SNAPSHOT_PREFIX="snap"
LOCKFILE=/tmp/back.lock

if [ -f $LOCKFILE ]; then
        echo "Lockfile $LOCKFILE exists, exiting!"
        exit 1
fi
touch $LOCKFILE


function xe_param()
{
    PARAM=$1
    while read DATA; do
        LINE=$(echo $DATA | egrep "$PARAM")
        if [ $? -eq 0 ]; then
            echo "$LINE" | awk 'BEGIN{FS=": "}{print $2}'
        fi
    done
}

echo "Taking Snapshots";

VMS=$(xe vm-list is-control-domain=false | xe_param uuid)

for VM in $VMS; do

  VM_NAME="$(xe vm-list uuid=$VM | xe_param name-label)"

  SCHEDULE=$(xe vm-param-get uuid=$VM param-name=other-config param-key=XenCenter.CustomFields.backup)
  RETAIN=$(xe vm-param-get uuid=$VM param-name=other-config param-key=XenCenter.CustomFields.retain)

  if [[ "$SCHEDULE" == "" || "$RETAIN" == "" ]]; then
    echo "$VM_NAME not scheduled"   
  else
    echo $VM_NAME;

    VM_SNAPSHOT_CHECK=$(xe snapshot-list name-label="$SNAPSHOT_PREFIX-$VM_NAME" | xe_param uuid)
    if [ "$VM_SNAPSHOT_CHECK" != "" ]; then
      echo "Found old backup snapshot : $VM_SNAPSHOT_CHECK"
      xe snapshot-uninstall uuid=$VM_SNAPSHOT_CHECK force=true
    fi;

    SNAPSHOT_UUID=$(xe vm-snapshot vm="$VM_NAME" new-name-label="$SNAPSHOT_PREFIX-$VM_NAME")
    echo "Created snapshot with UUID : $SNAPSHOT_UUID"
  fi;

  echo "DONE"
  sleep 60;
done

rm $LOCKFILE




