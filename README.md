# UTM

A fork of UTM to enable debugging of macOS guests on macOS 12+ hosts through the [Virtualization framework](https://developer.apple.com/documentation/virtualization)'s private GDB stub.

Credits to [@_saagarjha](https://twitter.com/_saagarjha) for both [ideas](https://twitter.com/_saagarjha/status/1411196869640822790) and [code](https://github.com/saagarjha/VirtualApple).

Last tested on Apple Silicon running on macOS Monterey 12.3.1 and Xcode 13.3.1.

## Requirements

Either disabling AMFI globally (possibly breaking some apps) or patching the entitlements check with a debugger.

The first approach involves:

1. [Disabling System Integrity Protection](https://developer.apple.com/documentation/security/disabling_and_enabling_system_integrity_protection).

1. Updating the `boot-args` variable:

    ```bash
    $ sudo nvram boot-args="amfi_get_out_of_my_way=1"
    ```

1. Adding the entitlement `com.apple.private.virtualization` to `Platform/macOS/macOS-unsigned.entitlements` before building and packaging UTM.

The second approach involves:

1. Disabling System Integrity Protection.

1. Installing an [Endpoint Security client](https://developer.apple.com/documentation/endpointsecurity) that hooks the execution of process `com.apple.Virtualization.VirtualMachine` and sends `SIGSTOP` to it before allowing it to execute, so to be able to attach to the process with a debugger before the entitlements check. This repository includes an example client in the form of the patch file [`MonitoringSystemEventsWithEndpointSecurity.patch`](MonitoringSystemEventsWithEndpointSecurity.patch) to be applied to the [sample client provided by Apple](https://developer.apple.com/documentation/endpointsecurity/monitoring_system_events_with_endpoint_security) (follow the building instructions for AUTH events and sign the app to run locally—no need for a Developer ID certificate and provisioning profile).

## Building

Follow the [original documentation](Documentation/MacDevelopment.md) to build and package UTM using prebuilt dependencies:

1. Clone submodules:

        UTM$ git submodule update --init --recursive

1. Download prebuilt dependencies from [GitHub Actions](https://github.com/utmapp/UTM/actions?query=event%3Arelease+workflow%3ABuild) and unzip the archive in the project's root directory.

        UTM$ ls sysroot-macOS-arm64/
        Frameworks/ bin/        host/       include/    lib/        libexec/    qapi/       sbin/       share/      ssl/        var/

1. Build and package UTM:

        UTM$ scripts/build_utm.sh -p macos -a arm64
        UTM$ scripts/package_mac.sh unsigned ../UTM.xcarchive /tmp/
        UTM$ mv /tmp/signed/UTM.app /Applications/

## Using

If AMFI has been disabled globally, from the UTM GUI boot the macOS guest and then attach to it from the host with any debugger supporting the GDB Remote Protocol:

```bash
$ lldb
(lldb) gdb-remote 5555
```

If instead the Endpoint Security client has been installed, from the UTM GUI boot the macOS guest (which will immediately stop) and then execute the script [`resume.sh`](resume.sh) to automatically patch the entitlements check with LLDB and resume execution; next, attach to the guest from the host with any debugger as explained just above.

**Important** The VM won't boot if UTM has been built unsigned and Network Mode is set to "Bridged" in the VM settings ([it seems to require special entitlements](https://github.com/utmapp/UTM/issues/3959)).

## License

Licensed under the Apache License 2.0 in accordance with the original license.
