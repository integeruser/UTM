# UTM

A fork of UTM to enable debugging of macOS guests on macOS 12+ hosts through the [Virtualization framework](https://developer.apple.com/documentation/virtualization)'s private GDB stub.

Credits to [@_saagarjha](https://twitter.com/_saagarjha) for both [ideas](https://twitter.com/_saagarjha/status/1411196869640822790) and [code](https://github.com/saagarjha/VirtualApple).

Last tested on Apple Silicon running on macOS Monterey 12.3.1 and Xcode 13.3.1.

## Requisites

1. [Disable System Integrity Protection](https://developer.apple.com/documentation/security/disabling_and_enabling_system_integrity_protection).

1. Either disable AMFI globally (possibly breaking some apps) or patch the entitlements check with a debugger.

    The first approach requires:

    1. Update the `boot-args` variable:

        ```bash
        $ sudo nvram boot-args="amfi_get_out_of_my_way=1"
        ```

    1. Add the entitlement `com.apple.private.virtualization` to `Platform/macOS/macOS-unsigned.entitlements`.

    The second approach requires:

    1. Write an [Endpoint Security client](https://developer.apple.com/documentation/endpointsecurity/monitoring_system_events_with_endpoint_security) that hooks the execution of process `com.apple.Virtualization.VirtualMachine` and sends `SIGSTOP` to it (e.g. with `kill(<pid>, SIGSTOP)`) before allowing it to execute; then, attach to the stopped process with LLDB, patch the entitlements check and continue execution:

        ```
        $ lldb -p <pid>
        (lldb) b xpc_connection_copy_entitlement_value
        (lldb) breakpoint command add
        thread return (id)xpc_bool_create(1)
        c
        DONE
        (lldb) c
        ```

## Building

Follow the [original documentation](Documentation/MacDevelopment.md) to build and package UTM using prebuilt dependencies.

## Using

After booting the macOS guest, connect from the host to port 5555 with any debugger supporting the GDB Remote Protocol:

```bash
$ lldb
(lldb) gdb-remote 5555
```

## License

Licensed under the Apache License 2.0 in accordance with the original license.
