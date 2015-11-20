#!/usr/bin/env python

import os
import pickle
import time

# Dumping environment
env = os.environ
print "Environment:" + env
try:
  pickle.dump(env, open("/tmp/crunch_script_debug.env", "w"))
except:
  raise
print "Also dumped environment to /tmp/crunch_script_debug.env"

print "Try docker exec -it <container_id> bash to enter the container and debug your real script"

print "Feeling very sleepy, give me a kill when you want me to wake up and die!"
while(1):
    time.sleep(60)
