# posi0nKFD
posi0nKFD is a fork of KFD with a toggleable tweak list and no firm or real objectives except offering a completely open source platform for modding using KFD. 
## Contributors:

GenericCoding (main developer)

Lrdsnow (Major contribution in device support via offsets and building IPAs.)

hrtowii (tweak and icon contributor and also a major contributor to KFD development in general.) 

iiem-ukur (revamped internal functionality for tweak list. https://github.com/GenericCoding/kfd/pull/4/commits/dd8c01ec8c2a7e9710ee226d5736fdd4ba6b08cb)
## Special thanks: 
felix-pb (Creator of KFD) 

wh1te4ever (major core utils developer for KFD which posi0nKFD depends on) 




# KFD

kfd, short for kernel file descriptor, is a project to read and write kernel memory on Apple
devices. It leverages various vulnerabilities that can be exploited to obtain dangling PTEs, which
will be referred to as a PUAF primitive, short for "physical use-after-free". Then, it reallocates
certain kernel objects inside those physical pages and manipulates them directly from user space
through the dangling PTEs in order to achieve a KRKW primitive, short for "kernel read/write". The
exploit code is fully contained in a library, [libkfd](kfd/libkfd.h), but the project also contains
simple executable wrappers for [iOS](kfd/ContentView.swift) and [macOS](macos_kfd.c). The public API
of libkfd is quite small and intuitive:

```c
enum puaf_method {
    puaf_physpuppet,
    puaf_smith,
};

enum kread_method {
    kread_kqueue_workloop_ctl,
    kread_sem_open,
};

enum kwrite_method {
    kwrite_dup,
    kwrite_sem_open,
};

u64 kopen(u64 puaf_pages, u64 puaf_method, u64 kread_method, u64 kwrite_method);
void kread(u64 kfd, u64 kaddr, void* uaddr, u64 size);
void kwrite(u64 kfd, void* uaddr, u64 kaddr, u64 size);
void kclose(u64 kfd);
```

`kopen()` conceptually opens a "kernel file descriptor". It takes the following 4 arguments:

- `puaf_pages`: The target number of physical pages with dangling PTEs.
- `puaf_method`: The method used to obtain the PUAF primitive, with the following options:
    - `puaf_physpuppet`:
        - This method exploits [CVE-2023-23536][1].
        - Fixed in iOS 16.4 and macOS 13.3.
        - Reachable from the App Sandbox but not the WebContent sandbox.
    - `puaf_smith`:
        - This method exploits [CVE-2023-32434][2].
        - Fixed in iOS 16.5.1 and macOS 13.4.1.
        - Reachable from the WebContent sandbox and might have been actively exploited.
- `kread_method`: The method used to obtain the initial `kread()` primitive.
- `kwrite_method`: The method used to obtain the initial `kwrite()` primitive.

If the exploit is successful, `kopen()` returns a 64-bit opaque file descriptor. In practice, this
is just a user space pointer to a structure needed by libkfd. However, since that structure should
not be accessed outside of the library, it is returned as an opaque integer. If the exploit is
unsuccessful, the library will print an error message, sleep for 30 seconds, then exit with a status
code of 1. It sleeps for 30 seconds because the kernel might panic on exit for certain PUAF methods
that require some cleanup post-KRKW (e.g. `puaf_smith`).

`kread()` and `kwrite()` are the user space equivalent of `copyout()` and `copyin()`, respectively.
Please note that the options for `kread_method` and `kwrite_method` are described in a separate
[write-up](writeups/exploiting-puafs.md). In addition, the initial primitives granted by those
methods can be used to bootstrap a better KRKW primitive. Finally, `kclose()` simply closes the
kernel file descriptor. They all take the opaque integer returned by `kopen()` as their first
argument.

[1]: https://support.apple.com/en-us/HT213676
[2]: https://support.apple.com/en-us/HT213814

---

## What are the supported OS versions and devices?

The later stage of the exploit makes use of various offsets. For the structures that have identical
offsets across all versions that I tested, I simply included their definitions under the
[static_types](kfd/libkfd/info/static_types/) folder. For the structures that have different
offsets, I built offset tables for them under the [dynamic_types](kfd/libkfd/info/dynamic_types/)
folder. Then, I map the "kern.osversion" of the device to the appropriate index for those offset
tables. Please check the function `info_init()`, located in [info.h](kfd/libkfd/info.h), for the
list of currently supported iOS and macOS versions. However, please note that I only tested the
exploits on an iPhone 14 Pro Max and a MacBook Air (M2 2022). Therefore, it is possible that the
offsets are actually different on other devices, even for the same OS version. Keep this in mind if
you get a "Kernel data abort" panic on a "supported" version. Fortunately, those offsets should all
be easily retrievable from the XNU source code.

On the other hand, in order to bootstrap the better KRKW primitive, the exploit makes use of certain
static addresses which must be retrieved from the kernelcache. This is a tedious process, which I
only carried out for the kernelcaches of certain iOS versions on the iPhone 14 Pro Max. Please check
the function `perf_init()`, located in [perf.h](kfd/libkfd/perf.h), for the list of currently
supported versions. Note that none of the exploits require the better KRKW primitive in order to
succeed. However, if you plan on doing research based on this project, then it is probably
worthwhile to add support for the better KRKW primitive for your own device!

---

##  How to build and run kfd on an iPhone?

In Xcode, open the root folder of the project and connect your iOS device.

- To build the project, select Product > Build (⌘B).
- To run the project, select Product > Run (⌘R), then click on the "kopen" button in the app.

---

## How to build and run kfd on a Mac?

In a terminal, navigate to the root folder of the project.

Optionally, to increase the global and per-process file descriptor limits, which will improve the
success rate especially on multiple consecutive runs, enter the command `make s` and type in the
sudo password.

- To build the project, enter the command `make b`.
- To run the project, enter the command `make r`.
- To build and run the project at once, enter the command `make br`.

---

## Where to find detailed write-ups for the exploits?

This README presented a high-level overview of the kfd project. Once a PUAF primitive has been
achieved, the rest of the exploit is generic. Therefore, I have hoisted the common part of the
exploits in a dedicated write-up:

- [Exploiting PUAFs](writeups/exploiting-puafs.md)

In addition, I have split the vulnerability-specific part of the exploits used to achieve the PUAF
primitive into distinct write-ups, listed below in chronological order of discovery:

-   [PhysPuppet](writeups/physpuppet.md)
-   [Smith](writeups/smith.md)

However, please note that these write-ups have been written for an audience that is already familiar
with the XNU virtual memory system.
