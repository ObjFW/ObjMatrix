PROG_NOINST = tests${PROG_SUFFIX}
SRCS = Tests.m

include ../buildsys.mk
include ../extra.mk

post-all: ${RUN_TESTS}

.PHONY: run
run:
	rm -f libobjmatrix.so.${OBJMATRIX_LIB_MAJOR}
	rm -f libobjmatrix.so.${OBJMATRIX_LIB_MAJOR_MINOR}
	rm -f objmatrix.dll libobjmatrix.${OBJMATRIX_LIB_MAJOR}.dylib
	if test -f ../src/libobjmatrix.so; then \
		${LN_S} ../src/libobjmatrix.so \
		    libobjmatrix.so.${OBJMATRIX_LIB_MAJOR}; \
		${LN_S} ../src/libobjmatrix.so \
		    libobjmatrix.so.${OBJMATRIX_LIB_MAJOR_MINOR}; \
	elif test -f ../src/libobjmatrix.so.${OBJMATRIX_LIB_MAJOR_MINOR}; \
	then \
		${LN_S} ../src/libobjmatrix.so.${OBJMATRIX_LIB_MAJOR_MINOR} \
		    libobjmatrix.so.${OBJMATRIX_LIB_MAJOR_MINOR}; \
	fi
	if test -f ../src/objmatrix.dll; then \
		${LN_S} ../src/objmatrix.dll objmatrix.dll; \
	fi
	if test -f ../src/libobjmatrix.dylib; then \
		${LN_S} ../src/libobjmatrix.dylib \
		    libobjmatrix.${OBJMATRIX_LIB_MAJOR}.dylib; \
	fi
	LD_LIBRARY_PATH=.$${LD_LIBRARY_PATH+:}$$LD_LIBRARY_PATH \
	DYLD_FRAMEWORK_PATH=../src:../src/runtime$${DYLD_FRAMEWORK_PATH+:}$$DYLD_FRAMEWORK_PATH \
	DYLD_LIBRARY_PATH=.$${DYLD_LIBRARY_PATH+:}$$DYLD_LIBRARY_PATH \
	LIBRARY_PATH=.$${LIBRARY_PATH+:}$$LIBRARY_PATH \
	${WRAPPER} ./${PROG_NOINST}; EXIT=$$?; \
	rm -f libobjmatrix.so.${OBJMATRIX_LIB_MAJOR}; \
	rm -f libobjmatrix.so.${OBJMATRIX_LIB_MAJOR_MINOR} objmatrix.dll; \
	rm -f libobjmatrix.${OBJMATRIX_LIB_MAJOR}.dylib; \
	exit $$EXIT

${PROG_NOINST}: ${LIBOBJMATRIX_DEP}

CPPFLAGS += -I../src
LIBS := -L../src -lobjmatrix ${LIBS}
LD = ${OBJC}
