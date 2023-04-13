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

# The following hack allows instead to attach to the VM early in the boot
# process. In addition to patching the entitlements check, the following command
# also inserts a conditional breakpoint on the routine retrieving the current
# vCPU program counter. The breakpoint will hit after around 30s; at that point,
# on another terminal window launch a second LLDB instance and start attaching
# to the VM by executing `gdb-remote 5555`, then quickly return to this first
# LLDB instance and resume execution of the stopped process with `c` (before the
# other LLDB times out). Only tested using VMs running on a single core.
#lldb --no-lldbinit -p $pid -s <(echo '
#image list
#
#b xpc_connection_copy_entitlement_value
#breakpoint command add
#    thread return (id)xpc_bool_create(1)
#    c
#DONE
#
#breakpoint set --func-regex hv_vcpu_run --one-shot true --auto-continue true
#breakpoint command add -s python
#    target = lldb.debugger.GetSelectedTarget()
#    process = target.GetProcess()
#    module = target.GetModuleAtIndex(0)
#    textsection = module.FindSection("__text")
#    textaddr = textsection.GetLoadAddress(target)
#    textbytes = process.ReadMemory(textaddr, textsection.GetByteSize(), lldb.SBError())
#
#    # 102458d64 e1 03 80 52     mov        w1,#0x1f
#    # 102458d68 7a 18 03 94     bl         __auth_stubs::_hv_vcpu_get_reg   # get pc from vCPU
#    # 102458d6c a0 00 00 35     cbnz       w0,LAB_102458d80
#    # 102458d70 e0 07 40 f9     ldr        x0,[sp, #local_18]
#    # 102458d74 fd 7b 41 a9     ldp        x29=>local_10,x30,[sp, #0x10]
#    # 102458d78 ff 83 00 91     add        sp,sp,#0x20
#    # 102458d7c ff 0f 5f d6     retab                                       # return pc, setting a breakpoint here
#    instrs = b"\xe1\x03\x80Rz\x18\x03\x94\xa0\x00\x005\xe0\x07@\xf9\xfd{A\xa9\xff\x83\x00\x91\xff\x0f_\xd6"
#    bpaddr = textaddr + textbytes.index(instrs) + len(instrs)-4
#    lldb.debugger.HandleCommand(f"breakpoint set -a {bpaddr:#x} -c \"$x0 >= 0xffff000000000000\" --one-shot true")  # this slows down boot a bit, will trigger after 30s
#    return True
#DONE
#
#c
#')
