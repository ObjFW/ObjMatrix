# ObjMatrix

## What is ObjMatrix?

ObjMatrix is a [Matrix](https://matrix.org) client library for
[ObjFW](https://objfw.nil.im).

It is currently in early development stages.

## How to build it?

You need [ObjFW](https://objfw.nil.im) and
[ObjOpenSSL](https://fossil.nil.im/objopenssl) installed in order to do this.

ObjMatrix uses modern Objective-C, and hence cannot be compiled with GCC, but
only with Clang. So install Clang first and ObjFW will automatically pick it up.

You can install them all like this:

    $ for i in objfw objopenssl objmatrix; do
          fossil clone https://fossil.nil.im/$i $i.fossil &&
          mkdir $i &&
          cd $i &&
          fossil open ../$i.fossil &&
          ./autogen.sh &&
          ./configure &&
          make &&
          sudo make install &&
          cd .. || break
      done

You might need to install your distribution's `-dev` packages for OpenSSL
beforehand. E.g. on Ubuntu:

    $ sudo apt install libssl-dev

## Contributing

Just create an account on the
[ObjMatrix Fossil](https://fossil.nil.im/objmatrix) and post your patch on the
[forum](https://fossil.nil.im/objmatrix/forum). After a few patches, you will
be granted commit access.
