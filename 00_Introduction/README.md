# 00 Introduction to the Journey

<p align="center" width="100%">
    <img width="100%" src="../resources/images/here_be_dragons.jpg">
</p>

_"Here be dragons."_ On the margins of ancient maps, where the known world gave
way to blank parchment, cartographers sometimes marked the boundary with these
words. Beyond that point lay seas that had not yet been sailed and lands that
had not yet been carefully measured. Places where the terrain was uncertain and
where, for all anyone knew, monsters might dwell.

In technical work there are similar boundaries. Specifications stop short, 
documentation grows thin, and the answers are no longer written down. What 
remains is the work of exploration - reading closely, experimenting carefully,
and gradually mapping the terrain for yourself.

Every craft has its unexplored regions, where the path forward is uncertain and
curiousity leads the way. That, is where the real adventure begins, and
perhaps unsurprisingly, where mystery starts to give way to understanding.

## Goal of the Journey
Here are my goals (and non-goals), for the journey.

+ To write firmware from scratch that does not rely on any board support 
package and runs on a least one real hardware platform. 

+ Follow the KISS principle: "Keep it simple, stupid!". The goal of the journey 
is first and foremost, to learn concepts for my self and by extension, to teach
fellow travelers like me along the way. We keep things practical as a rule of 
thumb to provide focused teaching of embedded concepts, without overwhelming 
ourselves with self-indulgent abstractions and unecessary complexity.

+ Practical before research. We start from absolutely nothing in this journey so
I emphasize doing and understanding before the advanced intellectual exploration.
That said, there will be times when I'll need to introduce (and implement) 
theory-based things (something to keep in mind).

+ Take lots of small steps to reach the final goal. I'll break the journey up
into lots of simple steps instead of taking large leaps. Adding just one simple
feature ontop of the existing work until all the parts are in place to call the
work a truly bare metal firmware.

## Development Environment Setup

I'm going to be using a Linux development environment for this course and you are
expected to do the same. So download and install your favorite/preferred Linux
development system. I'm using Ubuntu 24.04 and WSL where convenient.

For the hardware, my development kit of choice is the [Maxim32655FTHR Evaluation
Kit](../resources/datasheets/MAX32655FTHR.pdf). It has an integrated DAPLink
debug and programming Interface via the USB port so it's perfect for our needs
as no other additional hardware will be needed for this learning experience.

For the toolchain, we need the Arm [GCC](../resources/gnu/gcc.pdf) cross compiler
(Officially called the _GNU Arm Embedded Toolchain_ or _arm-none-eabi_[^1]),
Arm [binutils](https://www.gnu.org/software/binutils/),
GNU [Make](../resources/gnu/make.pdf), Arm gdb, 
and [Eclipse IDE for Embedded C/C++ Developers](https://www.eclipse.org/downloads/packages/releases/2025-12/r/eclipse-ide-embedded-cc-developers),

```bash
$ sudo apt-get install build-essential gcc-arm-one-eabi binutils-arm-none-eabi \
gdb-multiarch make git
```

Additionally, we need a clone of Analog Device's [OpenOCD](https://github.com/analogdevices/openocd)
fork which has all the TCL scripts we will need to flash and debug our firmware
ontop of Max32655. In order to build OpenOCD for our bare metal studies, follow
the steps below:

```bash
$ sudo apt-get install autoconf automake texinfo libtool pkg-config \
libusb-1.0-0-dev libhidapi-dev libftdi1-dev
$ git clone https://github.com/analogdevicesinc/openocd.git
$ cd openocd
$ ./bootstrap
$ ./configure --enable-cmsis-dap
$ make
$ sudo make install
```

Eventually, we will need to also configure our debugging environment from within
Eclipse as well. For now, let's just focus on getting our bare metal binary 
successfully built.

To save time and maintain focus, other tools and their corresponding 
installation and configuration instructions are not included anymore here.
Please refer to the official tool documentation for installation details.

## The Next Step
In the [next step](../01_Directory_Layout/README.md) of this journey we will explore how we would arrange our 
bare metal firmware source code layout as well as design our Makefile build
system to build our firmware.

[^1]: Section 14.1 of the Autoconf manual calls this specific naming convention
as *"target triplet"* which has the form 'cpu-vendor-os'. Therefore, 
arm-none-eabi means the CPU is ARM, there is no vendor, and the target OS is
the Embedded Application Binary Interface which defines how code is supposed to
interact at the binary level in an embedded environment (e.g. bare-metal).
