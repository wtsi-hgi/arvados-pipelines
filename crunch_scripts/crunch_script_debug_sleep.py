#!/usr/bin/env python

import os
import pickle
import time
import sys

# Dumping environment
#env = os.environ
#print "Environment:" + str(env)
#try:
#  pickle.dump(env, open("/tmp/crunch_script_debug.env", "w"))
#except:
#  raise
#print "Also dumped environment to /tmp/crunch_script_debug.env"

container = os.environ.get("HOSTNAME", "<container_id>")
node = os.environ.get("TASK_SLOT_NODE", "<task_slot_node>")
print "*******************************************************************************\nStarting debug session, try: `ssh %s docker exec -it %s tmux attach` to enter the container and run your real script interactively\n*******************************************************************************" % (node, container)

sys.stdout.flush()
os.execlp("tmux")

#print "Feeling very sleepy, give me a kill when you want me to wake up and die!"
#while(1):
#    time.sleep(60)
