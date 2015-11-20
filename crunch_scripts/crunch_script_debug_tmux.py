#!/usr/bin/env python

import os
import sys
import pty
import time

container = os.environ.get("HOSTNAME", "<container_id>")
node = os.environ.get("TASK_SLOT_NODE", "<task_slot_node>")
print "*******************************************************************************\nStarting debug session, try: `ssh %s docker exec -it %s tmux attach` to enter the container and run your real script interactively\n*******************************************************************************" % (node, container)

try:
  ( child_pid, fd ) = pty.fork()
except OSError as e:
  print "ERROR forking a pty: " + str(e)

if child_pid == 0:
  # in child
  print "Starting tmux..."
  sys.stdout.flush()
  os.environ["TERM"] = "screen-256color"
  try:
      os.execl("/usr/bin/tmux", "/usr/bin/tmux", "-2", "-u")
      # never returns
  except:
    print "ERROR cannot spawn tmux!"
    raise
else:
  # in parent
  os.read(fd, 100)
#  try:
#    tmux = os.fdopen(fd)
#  except:
#    print "ERROR cannot open fd from tmux"
#    raise
#  try:
#    while True:
#      print "TMUX: " + tmux.readline() ,
#  except IOError as e:
#    print "Got expected TMUX IOerror: %s" % str(e)
  print "Sleeping forever..."
  while True:
    time.sleep(1)
