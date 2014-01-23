#!/usr/bin/env python

import sys
import threading
import XenAPI

class CloneVDIThread(threading.Thread):
    """
        A threaded VDI.clone operation.
    """
    def __init__(self, name, session, vdi):
        threading.Thread.__init__(self)
        self.name = name
        self.session = session
        self.vdi = vdi

    def run(self):
        self.session.xenapi.VDI.clone(self.vdi)

def run_parallel(session, vdi, count):
    """
        Run count clones of vdi, in parallel.
    """
    threads = []
    for i in range(count):
        name = "thread-%d" % i
        thread = CloneVDIThread(name, session, vdi)
        print "starting %s" % name
        thread.start()
        threads.append(thread)
        print "kicked off %s" % name
    for thread in threads:
        print "waiting for %s" % thread.name
        thread.join()
        print "joined %s" % thread.name

def run_serial(session, vdi, count):
    """
        Run count clones of vdi, in serial.
    """
    for i in range(count):
        session.xenapi.VDI.clone(vdi)

if __name__ == "__main__":
    """
        Usage:
        ./clone_vdi <vdi-uuid> <count> <mode>

        <vdi-uuid>:
            The UUID of the VDI to clone.
        <count>:
            The number of clones to perform.
        <mode>:
            "parallel" or "serial".
    """
    vdi_uuid = sys.argv[1]
    count = int(sys.argv[2])
    mode = sys.argv[3]
    session = XenAPI.xapi_local()
    session.xenapi.login_with_password("root", "xenroot")
    vdi = session.xenapi.VDI.get_by_uuid(vdi_uuid)
    if mode == "parallel":
        run_parallel(session, vdi, count)
    elif mode == "serial":
        run_serial(session, vdi, count)
    else:
        raise RuntimeError("Unknown mode")
