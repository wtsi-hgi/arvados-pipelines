#!/usr/bin/env python

import os
import time
import sys

# Dumping environment
env = os.environ
print "Environment:" + str(env)
env_f = open("/tmp/crunch_script_debug.env", "w")
for var in os.environ.keys():
    print >>env_f, "export %s=\"%s\"" % (var, os.environ[var])
env_f.close()

container = os.environ.get("HOSTNAME", "<container_id>")
node = os.environ.get("TASK_SLOT_NODE", "<task_slot_node>")
print "*******************************************************************************\nStarting debug session, try: `ssh -t %s docker exec -it %s bash` to enter the container and run your real script interactively\n*******************************************************************************" % (node, container)

print "Feeling very sleepy, you'll have to kill me if you want me to end! (try: `ssh -t %s docker kill %s`)" % (node, container)
while(1):
    time.sleep(60)
