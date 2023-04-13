#!/usr/bin/env bash

while :
do
    # Assuming only one VM running
    pid=$(pgrep com.apple.Virtualization.VirtualMachine)
    if [ -n "$pid" ]; then break; fi
    sleep 1
done

# The following command spawns LLDB to patch the entitlements check, resume
# execution and detach.
lldb --no-lldbinit -b -p $pid -s <(echo '
image list

b _os_crash
breakpoint command add
    bt
DONE

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
')
