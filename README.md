# ObjMatrix

## What is ObjMatrix?

ObjMatrix is a [Matrix](https://matrix.org) client library for
[ObjFW](https://objfw.nil.im).

It is currently in early development stages.

## How to build it?

Install [ObjFW](https://objfw.nil.im) first, either via your distribution on by
following the instructions on how to compile it yourself. Make sure you compile
ObjFW using Clang, as ObjMatrix is written in modern Objective-C and hence
cannot be compiled with GCC.

Then install [ObjSQLite3](https://git.nil.im/ObjFW/ObjSQLite3):

    git clone https://git.nil.im/ObjFW/ObjSQLite3
    cd ObjSQLite3
    meson setup build
    meson compile -C build
    sudo meson install -C build

Now you can build and install ObjMatrix like this:

    git clone https://git.nil.im/ObjFW/ObjMatrix
    cd ObjMatrix
    meson setup build
    meson compile -C build
    sudo meson install -C build

You can run the tests like this:

    meson test -C build

## Contributing

Just create an account on [git.nil.im](https://git.nil.im) and create a pull
request.
