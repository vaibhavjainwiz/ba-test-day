#!/bin/sh

for i in {1..25}
#for i in 5
do	
	ns=$(echo "ba-test-day-"${i})
  oc delete project ${ns}
done
