#!/usr/bin/env bash

while :
do
    # assuming only one VM running
    pid=$(pgrep com.apple.Virtualization.VirtualMachine)
    if [ -n "$pid" ]; then break; fi
    sleep 1
done    

lldb --no-lldbinit -b -p $pid -s <(echo "
b xpc_connection_copy_entitlement_value
breakpoint command add
    thread return (id)xpc_bool_create(1)
    c
DONE
b main
breakpoint command add
    detach
DONE
c
")
