# ncurses C++ binding does not build with fil++ (libc++ headers in the
# pizfix); nothing in the image needs libncurses++, so disable it.
EXTRA_OECONF:append:class-target = " --without-cxx"
