#!/usr/bin/env python

import os
import sys
import pty

container = os.environ.get("HOSTNAME", "<container_id>")
node = os.environ.get("TASK_SLOT_NODE", "<task_slot_node>")
print "*******************************************************************************\nStarting debug session, try: `ssh %s docker exec -it %s tmux attach` to enter the container and run your real script interactively\n*******************************************************************************" % (node, container)

try:
  ( child_pid, fd ) = pty.fork()
except OSError as e:
  print "ERROR forking a pty: " + str(e)

if child_pid == 0:
  # in child
  sys.stdout.flush()
  try:
      os.execl("/usr/bin/tmux","/usr/bin/tmux","-2")
  except:
    print "ERROR cannot spawn tmux!"
    raise
else:
  # in parent
  try:
    tmux = os.fdopen(fd)
  except:
    print "ERROR cannot open fd from tmux"
    raise
  while True:
    print "TMUX: " + tmux.readline()
