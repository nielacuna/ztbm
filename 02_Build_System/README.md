# Build System
The purpose of introducing a build system into a project is straightforward. A
build system exists so that developers do not have to rely on memory, personal
notes, or repeated commands simply to build the project.

In most cases, embedded firmware and software projects consist of numerous
source files and header files distributed across multiple directories. Rather 
than remembering which files to compile, which compiler flags to use, and which
sequence of steps must be executed, these details are defined once as formal 
build rules. The build tool then executes those rules automatically and
consistently.

From that point forward, anyone working on the project can simply run `make`
and obtain the same correct result every time.

In this way, a build system saves time, reduces likelihood of human error, and
helps ensure that the project remains maintainable as it grows and evolves.

## Why Make and Not CMake or Any Other Build System for That Matter?
For the same reason we use assembly and C when developing bare-metal firmware.
These languages strike an excellent balance between control and productivity,
while still providing a clear view of what happens at the lower levels of the
system. Rather than hiding the build process behind complex tooling, it allows
us to describe the exact steps required to transform source code into a working
firmware image.

By writing these rules explicitly, we gain a clear view of how the different 
pieces of the system are compiled, assembled, and linked together. In that
sense, `make` serves the same role in the build process that C and assembly
serve in the firmware itself: it provides enough abstraction to remain
productive, while still exposing the underlying mechanics so that learners can
understand how everything is ultimately put together.

## The Case for Non-Recursive Make
Traditionally, many projects used recursive make where each subdirectory had
its own makefile and the top-level makefile just called `make -C subdir/` for
each directory.

The idea seemed natural: each folder is responsible for its own e.g. "it 
builds itself" so you do not have to manage everything in one place. However,
it came with some problems:

+ Make doesn't see the full dependency graph, so parallel builds (-j) can break 
or rebuild more than necessary.
+ It's easy to get subtle bugs when changes in one directory require rebuilding
something in another but the other subdirectory Makefiles don't know about it.
+ Debugging and maintaining the build became harder, because logic is scattered
across many files.

> [!NOTE]
> There is a famous paper by Peter Miller titled [Recursive Make Considered Harmful](../resources/papers/miller.pdf)
where Miller argues that the correct approach is to have one makefile for the
whole project - which became the inspiration for non-recursive _Make_ 
implementations. 

Using _GNU Make_ in non-recursive way means running `make` once at the base[^1]
of the project and letting it see and control the entire build at the same
time instead of jumping into each directory separately and delegating control
to other makefiles.

In creating our baremetal firmware, we will be employing the non-recursive
_Make_ approach over the recursive one. We will be using the official _GNU Make_
[manual](../resources/gnu/make.pdf) to develop our bare-metal build system.
This guide is not supposed to be a replacement for reading the documentation,
we will however explore the intricacies of _Make_ where it makes sense to
discuss them for context.

## The Toplevel Makefile
The purpose of the toplevel makefile is to serve as the central control file
for the entire build system. It acts as the entry point, coordinating all
aspects of the build process, and is an **appropriate location for defining
most project configuration variables**.
    
Initially, we will adjust the make parameters to reduce verbosity. By default,
_Make_ is informative: it prints the commands it executes and describes the
steps it is performing.

For now, we will create an empty toplevel makefile and gradually populate it
with the necessary build rules.
```Bash
adi-fw $ touch Makefile
```

### Good to Know Before Anything Else
**Make** is primarily a declaractive build system - i.e. it uses a rule-based
language to build and then eveluate a dependency graph ultimately deciding which
rules to execute.

So there is no execution flow in the traditional sense that a debugger could
step through. So it's a good frame of mind to never treat make like how you
would a scripting language like python or bash, or a compiled language like C.

#### Debug Primarily Through the Use of Print Messages
There are 3 _"print"_ facilities we can use to help us figure out what is wrong 
when working with makefiles.

> [!NOTE]
> Section 8.13 of the GNU Make [manual](../resources/gnu/make.pdf) shows us
some functions that let us print messages and more importantly, variable values
when running make.

+ `$(error text...)` generates a fatal error message where the message is
`text` and will terminate make where it is encountered.
+ `$(warning text...)` This function works similarly to the `error` function 
above except that make will not exit. 
+ `$(info text...)` does nothing more than print to standard output. No
makefile name or line number is added.

At any point in our firmware, we can use any of those to print variable values
in order to learn and gain more understanding about our makefile implementation.

### Silencing Make
`Make` by default tends to be somewhat verbose - printing each command it 
executes during the build process.

> [!NOTE] 
> Section 5.7.1 of the Make [manual](../resources/gnu/make.pdf) explains how
the `MAKE` variable works. The same manual also tells us what flags to pass
make so it will suppress its usual reporting.

Let's tweak that behavior now in our toplevel makefile before anything else.
```Makefile
MAKE:=$(MAKE) -s --no-print-directory
```
+ `-s` simply means silent.
+ `--no-print-directory` does exactly that. Do not print information that Make
is entering a directory. Pointless for a non-recursive build design? Maybe.

> [!NOTE]
> Additionally, Section 5.2 of the Make [manual](../resources/gnu/make.pdf)
talks about _Recipe Echoing_. Normally, `make` prints each line of the recipe
before it is executed. We call this _echoing_ because it gives the appearance
that you are typing the lines yourself. Prepend a `@` to suppress the echoing
of that line instead.

### Let's Define the Architecture and Board Makefile Fragments
I mentioned before that our bare-metal project will target only one Arm 
platform, we define that variable and all related variables as a default in our
toplevel makefile.
```Makefile
ARCH?=arm
ARCH_VER?=armv7-m
CPU?=cortex-m4
MCU?=max32655
```
Normally, it is the board level makefile found inside the `board/` directory
that should define these details because it alone has visibility on what CPU,
chips and devices it has. In fact, in our bare-metal implementation, the board
level makefile will override these variables. Let us do that now for our board:
`board/max32655fthr/board.mk`[^2].

```Makefile
ARCH:=arm
ARCH_VER:=armv7-m
CPU:=cortex-m4
MCU:=max32655
```
Notice the difference? we are not using the conditional assignment operator of
`Make`. We are now turning these variables into _expanded_ variables.

We also need a way to tell the build system what board to use, so back on our 
toplevel makefile, let's add a `BOARD` variable and pull the board level 
makefile in by including it.

```Makefile
BOARD?=max32655fthr

include board/$(BOARD)/board.mk
```
> [!NOTE]
> This sets the expectation that boards to plug into our baremetal codebase
should provide and implement their own `board.mk`.

Now that we have included the board makefile fragment, we are now sure about 
what the ARM details we will need to build our baremetal firmware. Let us
include the correct processor makefile fragments.
```Makefile
include $(ARCH)/$(ARCH_VER)/arch.mk
include $(ARCH)/$(CPU)/cpu.mk
```
Also create the empty makefile fragments as well which we will also populate
later.
```bash
adi-fw $ touch arm/armv7-m/arch.mk
adi-fw $ touch arm/cortex-m4/cpu.mk
```
> [!NOTE]
> Like what we realized with the board makefile fragment, this implies
that the build system expects this arrangement and format when looking for
architecture support in the future. Please keep this in mind.

### Define The Toolchain Parameters
We decided to use GNU bin utilities and GCC ARM for all our building
activities early on during our planning stage. Let's define all our tools now.
Start by creating a new makefile fragment called `build_rules.mk`.
```bash
adi-fw $ touch build_rules.mk
```
Then fill in the tools definition.
```Makefile
TOOLCHAIN_PREFIX:=arm-none-eabi

CC:=$(TOOLCHAIN_PREFIX)-gcc
AS:=$(TOOLCHAIN_PREFIX)-as
AR:=$(TOOLCHAIN_PREFIX)-ar
LD:=$(TOOLCHAIN_PREFIX)-ld
NM:=$(TOOLCHAIN_PREFIX)-nm
OBJDUMP:=$(TOOLCHAIN_PREFIX)-objdump
OBJCOPY:=$(TOOLCHAIN_PREFIX)-objcopy
```
> [!NOTE]
> The ARM GCC toolchain follows a `prefix-tool` naming format where the prefix
is usually `arm-none-eabi` for embedded firmware.

+ `gcc` is the main compiler we will be using
+ `as` is the GNU assembler, altho we will still be using gcc as our assembler 
driver. 
+ `ar` is the GNU archiver. Used to create a bundle of library files called an 
archive. Archives usually end with a `.a` extension.
+ `ld` is the GNU linker. like with GNU assembler, we will not use ld directly.
Instead, we use `gcc` as our main linker driver.
+ `nm` lists symbols. We normally use nm as extra tools for generating 
build reports for the bare-metal firmware binary we built.
+ `objdump` is the Swiss Army knife for inspecting binaries in 
bare-metal embedded work. Where `nm` work primarily on symbols, `objdump` 
can show disassemblies, sections and other detailed object information.
+ `objcopy` by all intents and purposes is a file converter. We normally build
our firmware to become an ELF so we can debug it while it is heavily under
development. We can generate hex file format and raw binary of the ELF file
post build using `objcopy` which is usually what other tools and people prefer
when distributing firmware binaries.

### Define the Build Rules Further
A typical make build system separates the build logic from the configuration
and the `build_rules.mk` was created for this specific purpose. After defining 
the toolchain parameters, we also add in the actual compile invocations here.

First, we will revisit how a typical build or compilation progresses.

1. Compile or Assemble all relevant source files into intermediate objects.
2. Link all the intermediate objecs and generate an output ELF file. 
3. Generate a binary or hex file from an output ELF.

#### Creating Rules in Make

> [!NOTE]
> Section 2.1 of the GNU Make [manual](../resources/gnu/make.pdf) describes a
`rule`. Section 4.1 defines the Rule Syntax. 

A simple makefile consists of _rules_ which take the following form:

```Makefile
targets ... : prerequisites
    recipe
    ...
```
+ `targets` are file names, ***separated by spaces*** and are usually the name
of files that are generated by a program. In our case, ARM gcc.
+ `prerequisite` is a file that is used as _input_ to create the `target`. 
Sometimes, a `target` can depend on multiple files.
+ `recipe` is an action that `make` carries out. We can have many recipes under
the same target.

I placed an emphasis on ***separated by spaces*** because it will play an
important role later in our makefile build rules. For now, just take note of
this concept.

Collectively, this combination of `target`, `prerequisite` and `recipe` is called
a _rule_ in the makefile. `make` carries out the recipe on the `prerequisites`
to create or update the target.

#### Output Baremetal Binary Filename

At this point, we now think of the name to give our baremetal. Let's give
our firmware a standard name across any project or board or architecture
platform we use. We will always generate a firmware called `adi-fw`.

In our toplevel makefile, let's define our output ELF, bin and hex.

```Makefile
FIRMWARE:=adi-fw

TARGET_ELF:=$(FIRMWARE).elf
TARGET_BIN:=$(FIRMARE).bin
TARGET_HEX:=$(FIRMWARE).hex
```
By default, `make` starts with the first target it encounters - which is called
the _default goal_. But `make` also defines a set of standard target for users
(section 16.6 Standard Target for Users), one of which is the 'all' target.
Let's define an `all` target now inside our `build_rules.mk`:

```Makefile
all: $(TARGET_ELF)
    @echo "Done building."
```
Now we are ready to include our `build_rules.mk` file inside out toplevel
makefile.

```Makefile
include build_rules.mk
```

#### A Gentle Introduction to Make's Pattern Rules

> [!NOTE] 
> Section 10.5.1 of GNU Make [manual](../resources/gnu/make.pdf) tells us about
_pattern rules_. A _pattern rule_ is like an ordinary rule, except that its
target contains exactly one '%' character. The target is considered a pattern
for matching file names. Similar to how you would use the asterisk `*` when
working on the terminal.

Therefore, a pattern rule `%.o: %.c` says how to make any file `stem.o` from 
another file `stem.c`.

#### Create The Pattern Rule For All .c Sources
After learning about _Pattern Rules_, we are now ready to start making the
pattern rule for all `.c` sources in our bare-metal firmware.

We start by defining a "global" variable where all other makefile fragments can
**append** their source codes. A good name for this global variable can be
`SRCS`.

> [!NOTE]
> GNU Make provides the append operator `+=` which we can use across all makefile
fragments in our bare-metal build system.

Makefile fragments will typically include their source codes to `SRCS` similar to 
the following:
```Makefile
SRCS+=drivers/adc/adc.c \
      drivers/dac/dac.c \
```

Each makefile fragment must give the complete relative path so that the 
toplevel Makefile can reference all the codes that the makefile fragment wants
to include in the build process. For now, let's just agree that `SRCS` variable
contains all the `.c` source codes we need to compile.

After all the makefile fragments have included their `.c`, we can expect to 
have a `SRCS` variable filled with all the sources we need.

This is now a good time to remember the definition of `targets` - they are 
filenames ***separated by spaces***. And that is what the `+=` did to our `SRCS`
variable. `SRCS` is a space separated list of all `.c` codes we need to 
compile.

**BUT!** `.c` is the source file, we want intermediate objects `.o` which are
the compiled versions of our `.c` files. We need to convert them and there are 
two ways to do this:

> [!NOTE]
> Section 6.3.1 of the GNU Make [Manual](../resources/gnu/make.pdf) talks about
_Substitution Reference_ which basically _substitutes_ the value of a variable 
with alterations you specify.
```Makefile
OBJS+=$(SRCS:.c=.o)
```

**OR**

> [!NOTE]
> Section 8.2 of the same Make [Manual](../resources/gnu/make.pdf) shows us 
some builtin functions for string manipulation. We can see that we can also 
use the function called _"patsubst"_ to also modify our string variables - 
especially one as trivial as just changing all `.c` extensions in filenames to 
`.o`.
```Makefile
OBJS+=$($(patsubst %.c,%.o,$(SRCS))
```
We can choose one or the other, but for now, lets go with the first one as it is 
more terse and can easily fit inline into rules or recipes if we need it.

Now that we have converted all `.c` into `.o` and assigned them all to the `OBJS`
variable, we now have a properly formatted (_e.g. space separated_) prerequisites
we can use for our pattern rule. First we let make know that all `.o` files
are prerequisites for building `TARGET_ELF`. Let's rewrite our initial build
rule again.
```Makefile
all: $(TARGET_ELF)
    @echo "Done building."

$(TARGET_ELF): $(OBJS)
    @echo "LD $@"
    @touch $(TARGET_ELF)

%.o: %.c
    @echo "CC $@"
```
When make sees that it needs to build `$(TARGET_ELF)`, it sees a space 
separated list of `.o` files as its prerequisites, so it tries to find rules
on how to build those files. It sees our pattern rule `%.o: %.c` so `make`
uses it immediately. Right now, the only recipe is sees is a print message.

Also notice that for now, we simply _touch_ our ELF file instead of linking all
the objects. This achieves the same purpose, which is when the rule is run, a
`$(TARGET_ELF)` file is created.

#### Make Automatic Variables
The pattern rule for creating objects  has one glaring problem. We need a
recipe to do the actual compiling - right now we only print a message. We are
using `%.o`and `%.c` but how do we actually know what the actual filename is
so we know what to pass to the GCC compiler (we can't actually use 
`gcc %.c -o %.o` after all). 

> [!NOTE]
> `Make` solves this problem by providing us with _Automatic Variables_ described 
more thoroughly in section 10.5.3 in the Make documentation. 

The two automatic variables we are interested in right now are as follows:

+ `$@` This resolves to the file name of the target of the rule e.g. the 
actual filename that `%.o` expands to become.
+ `$<` This is the name of the first prerequisite e.g. the `%.c` which is the
one and only prerequisite for each `%.o`.

#### Compile! Don't Link... For now.
So we have our input source file described by `$<` as well as our output object
file described by `$@`. How do we tell GCC to compile just this one code and
generate an intermediate object file `.o` from it?

Projects are rarely just a single source file. Usually we have large code base 
scattered across multiple files and in multiple directories. So compilation is
done in stages. All source file are first turned into intermediate object files,
and only afterward are they combined (_linked_) into the final executable. This
approach exists for several practical and historical reasons.

+ **Separate compilation** - allows each module to be developed and compiled
separately.
+ **Faster rebuilds** - If only one file changes, only that file needs to be
recompiled.
+ **Scalable build systems** - Build systems like `make` depend on object
files, they track dependencies on object files so only the necessary pieces are
rebuilt. This makes large projects manageable.
+ **Historical and Practical Tradition** - This model of binary generation
dates back to early Unix toolchains:
```
source -> object -> link -> executable (ELF)

source -> object -> link -> executable (ELF) -> bin

source -> object -> link -> executable (ELF) -> hex
```
+ **Support Libraries** - Libraries are simply collections of `.o` files. The
linker extracts only the needed modules. This modular design is one of the
oldest and most durable conventions in systems programming.

> [!NOTE]
> The GCC [manual](https://gcc.gnu.org/onlinedocs/gcc-15.2.0/gcc.pdf) provides
us with the option to just "compile" via the `-c` parameter.
```
`-c` Compile or assemble the source files, **but do not link**. The linking
stage is not done. The ultimate output is in the form of an object file for
each source file.
```
For now, we are happy with just this single switch. There are lots more we need
to add but they each deserve sections of their own for discussion. We write our
pattern rule now like so:

```Makefile
%.o: %.c
    @echo "CC $@"
    @$(CC) -c -o $@ $<
```
+ `@` means do not echo this command invocation
+ `$(CC)` is our toolchain which will expand to `arm-none-eabi-gcc`.
+ `-c` is GCC flag we discussed that will instruct it to compile only and
generate
intermediate object.
+ `-o` is the GCC switch to describe the output of the compile result notice
that we use the `$@` automatic variable.
+ `$<` is another automatic variable which expands to the source code we need
to compile.

#### CFLAGS Variable
`$(CC) -c -o $@ $<` is only the minimal form. For real firmware work, we must
pass additional compiler flags. Some of these are detailed below:

+ **Architecture specific flags** - We need to pass compiler flags that tune the
compiler to the architecture or platform we want our firmware to run on. e.g.
turn on Thumb mode or not among other things.
+ **Compiler warnings** - Maybe even flag all warnings as errors.
+ **Debugging support** - Enable the compiler to generate compatible debug
symbols.
+ **non-hosted** Remove compiler assumptions about our generated code running
on hosted environments (-ffreestanding)
+ **Optimization** Define the optimization level.
+ **Include directories** - Define the include directories for our baremetal
firmware.
+ Generate header dependency information.
+ **C startup code & standard library** - It is our option to include or not 
the standard C runtime library (called the **crt**) and/or startup code.
+ **Compile time constants** - some drivers would need to define their own 
compile time constants or the project itself could define project-wide compile
time constants.

Similar to what we did with the `SRCS` variable, we take advantage of the `+=`
append operator of `Make` and let everyone add their own CFLAG if they feel the
need to do so.

Let us update our pattern rule again for generating intermediate objects to add 
our `CFLAGS` variable.
```Makefile
%.o: %.c
    @echo "CC $@"
    $(CC) $(CFLAGS) -c -o $@ $<
```

There is no `build/` directory created here at all. Which means all our
intermediate object file `.o` will be created on the same directory as the `.c`.

### Define the Application We will Build for Our Baremetal
If it is not clear yet, our `app/` directory is where we will put all our 
projects. Application is an abstract concept, by that, what I mean is an
application is not directly tied to a specific board. In fact, we can re-target
our application to run on multiple different boards even. We now define that
the structure for our apps folder is really `apps/<application_name>`.

To support this, let's add an `APP` global variable to our toplevel makefile.
This `APP` variable also happens to be the directory name of our application 
inside the `app/` directory. Let's make a "hello world" application which 
provides its own makefile fragment.

```bash
adi-fw $ mkdir app/hello_world/
adi-fw $ touch app/hello_world/app.mk
```
> [!NOTE]
> This indicates that our build system assumes each application will have its 
own `app.mk` makefile fragment to hook itself to the build system.

Now we add these details to our toplevel makefile and also pull in the
application level makefile fragment.

```Makefile
APP?=hello_world

include app/$(APP)/app.mk
```
We will leave it up to the application makefile fragment `app.mk` to determine 
what `CFLAGS` or other settings to add to the entire project. Normally, the
`app.mk` would be interested in adding relevant application specific compile
time constant macros to the `CFLAGS` via the GCC `-D` flag. More about this later.

### More CFLAGS
Most modules in our baremetal will need to add their own `CFLAGS` aswell. Any 
makefile fragment can choose to append to the global `CFLAGS` via the make
append operator `+=`.

#### Adding our Bare-metal Firmware Header Directory

**Discussion on system headers versus local headers**

> [!NOTE] 
> Section 6.10.2 of the C standard C99 [Draft Copy](../resources/standards/n1570.pdf)
makes mention of the form of the `#include` preprocessing directive. It can take
either the form `#include <h-char-sequence>` or it's second form 
`#include "h-char-sequence"`.

But the C standard does not really define the parameters for differentiating
the `< >` form or `" "` form. It is left up to the implementation how they are
processed. So, let's dig through the documentation of our toolchain. In GCC
land, all preprocessing is **not done** by the compiler GCC itself, instead,
that job is for another program called the C Preprocessor [cpp](../resources/gnu/cpp.pdf).

> [!NOTE]
> Section 2.1 of the GNU CPP documentation defines the include syntax.

+ `#include <file>` variant is used for **system header** files. It searches for 
a file named _file_ in a standard list of system directories. You can prepend
additional directories to this list by using the `-I` option of gcc.
+ `#include "file"` variant is used for header files of your own program. It 
searches for a file named _file_ first in the directory containing the current
file, then in the quote directories and then the same directories used for _<file>_.
You can prepend directories to this list of quote directories with the `-iquote`
option.

In our case, let us use the first option. Back to our toplevel makefile, let us
now add one of our first global compiler `CFLAGS`:
```Makefile
CFLAGS+=-Iinclude/
```
`include/` corresponds to the directory called `include/` in our `adi-fw`
directory layout. For a header file named `bare-metal.h` found inside our
`include/` directory, we should do `#include <bare-metal.h>`.

We can also add directories inside the include folder to group related headers.

#### Adding Debug Symbols
During development, we are constantly checking out things and verifying our
code's logic correctness and a whole slew of things. We can instruct GCC to add
debug symbols to our baremetal firmware to allow a debugger (like gdb) to
understand the program in terms of the original source code and not just raw
machine instructions. Without debug symbols, debugging becomes extremely
difficult. Adding debug symbols therefore:

1. Enables us and the debugger to map machine code back to source code.
2. Enables us to view variables and structures, without debug symbols, the
debugger cannot interpret memory contents as variables (like struct fields,
array indexes, etc).
3. Helps us to set breakpoints by function or line.
4. Provides us with meaningful stack traces. 
5. Program flow inspection like step, next and finish only work properly when
the debugger knows function boundaries and line numbers.

**DWARF Debugging Format**
If firmware binaries are called "elf", then the debugging information inside them
is called "dwarf". [DWARF](../resources/standards/dwarf-2.0.0.pdf)
does not particularly stand for anything other than a playful counterpart to
ELF. We will be focusing primarily on the ARM
[32-bit extensions](../resources/standards/aaelf32.pdf) to the ELF format.

We will dive into ELF later in our bare-metal journey to better understand 
firmware sections e.g. what section gets loaded to read-only memory, what areas
are executable, what areas are readable and writeable, etc.

I will also create a [writeup](../writeups/ELF.md) exploring the ELF standard.

> [!NOTE]
> In section 3.11 of the GCC [manual](../resources/gnu/gcc.pdf) gives us
options for debugging our program thru the `-g` flag and its variants.


```
`-g` tells GCC to generate standard debugging information depending on the 
operating system's native format. 

`-ggdb` also generates debug information but tuned specifically for the GNU
debugger (GDB). This implies that _"extra"_ debugging information that is 
optimized for GDB usage.
```

What flag to use? `-g` is usually sufficient. I have had success in both `-g`
and `-ggdb` but only because I do all my developments inside Linux and use
mostly GNU toolchain and utilities as well.

Now that we know how the flag for turning on debugging symbols in GCC, let's 
add it to our `CFLAGS` in our toplevel makefile.

```Makefile
CFLAGS+=-ggdb
```

#### Adding Optimization Level
An optimization level is a setting that tells GCC how aggressively is should 
improve the generated machine code.

When GCC compiles a program, it can either:
1. produce code that closely follows the source
2. or transform the code to make it smaller, faster and more efficient.
The optimization level controls how much of the transformations mentioned above 
happens.

**When would you usually want optimizations?** 

1. Primarily when you are releasing final, well debugged, stable code. 
2. When you need performance critical code
3. When you want to reduce firmware binary size. Optimization is not only about 
speed, sometimes, it is about size as well.
4. Sometimes optimization helps in power efficiency. Less instructions to execute
means lesser CPU time and lower power consumption. 

**When you don't want optimizations?**

1. During debugging. When optimization is enabled, the compiler may suddenly 
remove variables (e.g. make them purely register based only and not memory), 
reorder instructions, inline functions and eliminate entire code paths.
2. During early development, the goal is to make the code logic work. 

There is a famous quote from a computer science illuminary Donald Knuth who
once said:

> "Premature optimization is the root of all evil."

This is not to say optimization is bad. He was just pointing out the fact that 
optimizing too early in development ultimately leads to bad design and more
often than not, wasted effort.

Developers often:
+ complicate code unnecessarily
+ optimize paths that are not performance bottlenecks
+ sacrifice readability and correctness

before they even know where the real performance issues are.

**When Optimization Becomes Bad**

Too much of anything is bad. Very high and aggressive optimization levels almost
always does more harm than good. In fact, most production builds I've come
across only go up to level 2. Even the Linux kernel only goes as high as
[2](https://github.com/torvalds/linux/blob/master/Makefile#L893).

Although nothing is stopping us really from going as high as the compiler allows,
we could use level 2 as a rule of thumb and leave it up to the wisdom of the
developers who know more than us - they choose this number for a good reason.

> [!NOTE]
> GCC provides us with the -O (capital letter O not zero) flag where we can have
values as low as 0 and as high as 3. It also gives other optional parameters 
to further tweak what kind of optimization the user wants to achieve like
-Os which is optimize for size.

For now, let us enable the `-Og` optimization flag in the toplevel makefile 
since we are just learning and are also in active development.

```Makefile
CFLAGS+=-Og
```

#### Header Dependency
When we talk about makefile rule prerequisites, we usually mean the `.c` source
code and conveniently forget that we also have `.h` headers as part of the code.
We typically do not put explicit headers in prerequisites (altho nothing is
stopping us from doing so). In fact, if you review our _pattern rule_, there is
no `.h` anywhere in our prerequisites.

```Makefile
%.o: %.c
    @echo "CC $@"
    $(CC) $(CFLAGS) -c -o $@ $<
```

We can leverage GCC to generate a dependency file for us which we can 
conveniently include in our makefile. Since GCC will parse the `.c` codes
for us anyway, it can automatically update the dependency tracking - e.g. if
we suddenly update our headers and remove/rename one or two, we don't need to
update this removal anywhere else except in our source code.

> [!NOTE]
> Section 3.14 of the GCC [manual](../resources/gnu/gcc.pdf) introduces us some
flags to control the C preprecessor with regards to header dependency
generation.

The few that we probably need are the following:
+ `-MMD` is like `-MD` exception it mentions only user header files, not
system header files.
+ `-MP` option is for adding a phony target for each dependency other than the
main file.

We normally, skip adding of system headers like _stdio.h_ and _stdlib.h_ as 
dependencies, since they almost never change contents and will never move.

Additionally, we want our phony to exist so that the next build will not
complain if every we delete a header due to ongoing development.

Given all these new flags, let us modify now our _pattern rule_. Yes. 
_Pattern rule_ not `CFLAGS`. Bite me. In our `build-rules.mk` file:

```Makefile
%.o: %.c
    $(CC) $(CFLAGS) -MMD -MP -c -o $@ $<
```

I'm going to do another [writeup](../writeups/makefile_header_dependency.md)
exploring this dependency issue so we can appreciate the leg work being done
by GCC for us here and why this is an important problem to solve when working
with makefiles.

The thing to note here is that our compilation because of the additional `-MMD`
flag now also generates a dependency file with a `.d` extension depending on
the file that we are compiling. If we are compiling a file named `file.c`,
a `file.o` and a `file.d` will be generated now.

This dependency file is especially generated to be included in our makefile.

_But if the dependency `.d` file is generated during compilation, that means it
does not exist on the first compilation, wouldn't make complain about including
a file `.d` that does not exist?_

_**Yes it will.**_

> [!NOTE]
**Page 14** of the GNU Make [manual](../resources/gnu/make.pdf) shows us a way
to use include that will simply _ignore_ a makefile that does not exist or
cannot be remade with no error message: `-include filenames...`.

> [!NOTE]
> `-include_` acts like `_include_` in every way except that there is no error
(not even a warning) if any of the _filenames_ (or any prerequisites of any 
_filenames_) do not exist or cannot be remade.

For this purpose, we shall use the `-include` when pulling in header dependency
files `.d`. Let us do it now in our `build_rules.mk`

```Makefile
-include $(SRCS:.c=.d)
```

We are already familiar with this syntax. This simply means, convert first all
filenames in our space separated list of sources codes ending with `.c` to `.d`
and include them but don't complain if they do not exist.

#### Architecture Specific GCC Compiler Flags
We will revisit what `CFLAGS` to add when we discuss the ARMv7/Cortex-M4
architectures. We will leave it up to the architecture makefile fragment to
add to the CFLAGS when it comes to MCU and arch specific flags.

#### The Clean Rule
We don't always want to build and compile. Sometimes, we want to rid our 
workspace of all of our build artifacts and stale intermediate objects, and
start from a fresh state. Let us define a `clean:` rule that does just that.
```Makefile
.PHONY: clean
clean: 
	@echo "removing $(TARGET_ELF)..."
	@rm -rf $(TARGET_ELF)
	@echo "removing all object files..."
	@rm -rf $(SRCS:.c=.o)
	@echo "removing all deps..."
	@rm -rf $(SRCS:.c=.d)
	@echo "done."
```
At this point these are all pretty straightforward, except for the `.PHONY`
line.

Before we delve into what `.PHONY` does, let us go back to our makefile 
`clean:` rule above. What happens if we accidentally also have a file named 
_"clean"_ in our directory and did not declare `clean` as phony?

Make will think that the target `clean` already exists and is up to date. So it
will not run the rule e.g. we will not `rm` anything at all.

> [!NOTE]
Section 4.5 of the GNU Make [manual](../resources/gnu/make.pdf) talks about
_Phony Targets_. A phony target is a file that does not really exist. Rather,
it is a name of a recipe to be executed when you make an explicit request.

Normally, we want to declare all rules that correspond to actions we want to do
as _phony_. In most cases, there will never be a file named `clean`. `clean`
in our case refers to an action we want to do, and not a file or target we want 
to build. So we declare `clean` as `phony`. In the off-chance that a `clean`
file does exist, then make still execute `clean` as if the file `clean` does 
not exist or is not up-to-date.

## Create OTher Remaining Makefile Fragments

**Let's create our empty `drivers/` makefile fragment**
```Bash
adi-fw $ touch drivers/drivers.mk
```
**Let's create our `lib/` makefile fragment**
```Bash
adi-fw $ touch lib/libs.mk
```
**Then add them both to our toplevel makefile**
```Makefile
include drivers/drivers.mk
include lib/libs.mk
```

## Giving the Build System and Initial Spin

We obviously want to see the fruits of our labor however meager they may seem 
right now. And with good reason. There is a classic mantra in aviation and 
engineering, often phrased exactly as:

> "Test what you fly, and fly what you test."

Testing early and testing in small increments is a fundamental principle in
engineering because it reduces risks, catches errors quickly, and most 
importantly, it keeps complexity manageable.

Let's try to see if our build system works (at this point):
+ it creates an intermediate object
+ it's able to find our include directory
+ it generates header dependency
+ it uses our correct CFLAGS

1. Create a `fwtest.h` file inside the `include/` directory with the following
contents.
```C
#ifndef __FWTEST_H__
#define __FWTEST_H__

void fwtest_init();

#endif /* __FWTEST_H__*/
```

2. Create a directory inside include called `another`.
```bash
adi-fw $ mkdir include/another
```

3. Create another header file called `fwtest2.h` inside the `another/` 
directory with the following contents.
```C
#ifndef __ANOTHER_FWTEST2_H__
#define __ANOTHER_FWTEST2_H__

void fwtest2_init();

#endif /* __ANOTHER_FWTEST2_H__*/
```

4. Create a file called `fwtest.c` in our `lib/` directory with the following
contents.
```C
#include <fwtest.h>
#include <another/fwtest2.h>

void fwtest_init()
{
    return;
}

void fwtest2_init()
{
    return;
}
```

5. Let's update our `lib/lib.mk` makefile fragment and add our `fwtest.c` to
`SRCS`.

```Makefile
LIB_SRCS+=fwtest.c

SRCS+=$(patsubst %.c, lib/%.c, $(LIB_SRCS))
```
> [!NOTE]
> Note here that since we are technically working in the base directory 
where our toplevel makefile is, we need to add the corresponding parent 
directory `lib/` to all lib sources. The same needs to be done for all other
directories.

6. Let's try running make now.
```Bash
adi-fw $ make
CC lib/fwtest.o
LD adi-fw.elf
Done building.
```

7. Inspect if an intermediate object file `lib/fwtest.o` is generated.
```Bash
adi-fw $ test -b lib/fwtest.o | echo $?
1
```
If lib/fwtest.o does not exist, it will print `0` instead of `1`.

8. Inspect the generated dependency lib/fwtest.d. It should show that 
`lib/fwtest.o` prerequisites are the two header files we included. There must
also be empty rules for these two header files.
```Bash
adi-fw $ cat lib/fwtest.d
lib/fwtest.o: lib/fwtest.c **include/fwtest.h include/another/fwtest2.h**
include/fwtest.h:
include/another/fwtest2.h:
```
9. We just built our firmware without changing anything, let's see if `make` is
able to see that there is no need to rebuild anything when we invoke `make`
again.
```Bash
adi-fw $ make
Done building.
```
Notice that `CC lib/fwtest.o` is not anymore displayed. Which means our rule
did not run.
10. Now let us test if our build system picks up on header updates and rebuilds
sources which use the updated headers. Edit `include/another/fwtest2.h` to 
add something like `#define FWTEST  1` and save it.
```C
#ifndef __ANOTHER_FWTEST2_H__
#define __ANOTHER_FWTEST2_H__

#define FWTEST  1

void fwtest2_init();

#endif /* __ANOTHER_FWTEST2_H__*/
```
11. Since our `lib/fwtest.c` includes `another/fwtest2.h` that means 
`lib/fwtest.o` needs to be rebuilt - which also means our target elf also 
needs to be rebuilt. Updates propagate up the dependency chain afterall.
```Bash
adi-fw $ make
CC lib/fwtest.o
LD adi-fw.elf
Done building.
```
12. Let's test our clean rule by running `make clean`
```Bash
adi-fw $ make clean
removing ad-fw.elf...
remove all object files...
removing all deps...
done.
```

Look through the `adi-fw/lib/` directory and try to find `fwtest.o` and 
`fwtest.d`. Lastly see if our `adi-fw.elf` still exists too - they should all
be gone.

### Updating Our .gitignore File

This is a good time to update our `.gitignore` file. We would need to put all
_"generated"_ files here. This means all binaries, dependencies, elf, etc that 
are not source codes or scripts.

```.gitignore
# ignore all generated files
*.elf
*.bin
*.hex
*.o
*.d
```

## Next Steps
We now have a directory layout with _sort of_ working build system. In the
[next step](../03_Arm_Makefile_Fragment/README.md), we will be talking a little
bit about Arm and how it ties to how we will be doing the makefile fragment for 
our `arm/` directory.

[^1]: We call this Makefile the "toplevel" makefile.
[^2]: By long standing convention, only the toplevel makefile is invoked 
directly, that is why it is named `Makefile`. Every other makefile fragment is 
included, so we just use whatever appropriate name for the makefile fragment and
just suffix it with `.mk` to indicate that its a makefile fragment. These are just 
conventions, not strict rules that GNU `Make` imposes, you are free to use
whatever naming convention you want for your own makefile fragments.
