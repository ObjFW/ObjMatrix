AC_INIT(ObjMatrix, 0.1, js@nil.im)
AC_CONFIG_SRCDIR(src)
AC_CONFIG_AUX_DIR(build-aux)
AC_CONFIG_MACRO_DIR(build-aux/m4)

for i in configure.ac build-aux/m4/*; do
	AS_IF([test $i -nt configure], [
		AC_MSG_ERROR([$i is newer than configure! Run ./autogen.sh!])
	])
done

BUILDSYS_INIT

AC_CHECK_TOOL(OBJFW_CONFIG, objfw-config)
AS_IF([test x"$OBJFW_CONFIG" = x""], [
	AC_MSG_ERROR(You need ObjFW and objfw-config installed!)
])

AS_IF([$OBJFW_CONFIG --package ObjOpenSSL], [
	OBJFW_CONFIG_FLAGS="$OBJFW_CONFIG_FLAGS --package ObjOpenSSL"
], [
	AC_MSG_ERROR(ObjOpenSSL not found!)
])
AS_IF([$OBJFW_CONFIG --package ObjSQLite3], [
	OBJFW_CONFIG_FLAGS="$OBJFW_CONFIG_FLAGS --package ObjSQLite3"
], [
	AC_MSG_ERROR(ObjSQLite3 not found!)
])

test x"$OBJC" = x"" && OBJC="$($OBJFW_CONFIG --objc)"

AC_LANG([Objective C])
AC_PROG_OBJC
AC_PROG_OBJCPP
AC_PROG_LN_S
AC_PROG_INSTALL

CPP="$OBJCPP"
CPPFLAGS="$CPPFLAGS $OBJCPPFLAGS"
CPPFLAGS="$CPPFLAGS $($OBJFW_CONFIG $OBJFW_CONFIG_FLAGS --cppflags)"
OBJCFLAGS="$OBJCFLAGS $($OBJFW_CONFIG $OBJFW_CONFIG_FLAGS --objcflags)"
LDFLAGS="$LDFLAGS $($OBJFW_CONFIG $OBJFW_CONFIG_FLAGS --ldflags)"
FRAMEWORK_LIBS="$($OBJFW_CONFIG $OBJFW_CONFIG_FLAGS --framework-libs) $LIBS"
LIBS="$($OBJFW_CONFIG $OBJFW_CONFIG_FLAGS --libs) $LIBS"

AX_CHECK_COMPILER_FLAGS(-Wdocumentation,
	[OBJCFLAGS="$OBJCFLAGS -Wdocumentation"])

AC_CHECK_TOOL(AR, ar)
AC_PROG_RANLIB
AC_ARG_ENABLE(shared,
	AS_HELP_STRING([--disable-shared], [do not build shared library]))
AS_IF([test x"$enable_shared" != x"no"], [
	BUILDSYS_SHARED_LIB
	AC_SUBST(OBJMATRIX_SHARED_LIB, "${LIB_PREFIX}objmatrix${LIB_SUFFIX}")
	AC_SUBST(EXCEPTIONS_LIB_A, "exceptions.lib.a")
	AC_SUBST(EXCEPTIONS_EXCEPTIONS_LIB_A, "exceptions/exceptions.lib.a")

	BUILDSYS_FRAMEWORK([
		AC_SUBST(OBJMATRIX_FRAMEWORK, "ObjMatrix.framework")
	])
])
AC_ARG_ENABLE(static, AS_HELP_STRING([--enable-static], [build static library]))
AS_IF([test x"$enable_static" = x"yes" -o x"$enable_shared" = x"no"], [
	AC_SUBST(OBJMATRIX_STATIC_LIB, "libobjmatrix.a")
	AC_SUBST(EXCEPTIONS_A, "exceptions.a")
	AC_SUBST(EXCEPTIONS_EXCEPTIONS_A, "exceptions/exceptions.a")
	AC_SUBST(LIBOBJMATRIX_DEP, "../src/libobjmatrix.a")
])

AS_IF([test x"$GOBJC" = x"yes"], [
	OBJCFLAGS="$OBJCFLAGS -Wall -Werror -Wwrite-strings -Wpointer-arith"

	old_OBJCFLAGS="$OBJCFLAGS"
	OBJCFLAGS="$OBJCFLAGS -Wcast-align"
	AC_MSG_CHECKING(whether -Wcast-align is buggy)
	AC_TRY_COMPILE([
		#ifdef __has_attribute
		# if __has_attribute(objc_root_class)
		__attribute__((__objc_root_class__))
		# endif
		#endif
		@interface Foo
		{
			struct objc_class *_isa;
		}
		@end

		@implementation Foo
		- (void)foo
		{
			struct objc_class *c = _isa;
			(void)c;
		}
		@end
	], [
	], [
		AC_MSG_RESULT(no)
	], [
		AC_MSG_RESULT(yes)
		OBJCFLAGS="$old_OBJCFLAGS"
	])
])

AS_IF([test x"$cross_compiling" = x"yes"], [
	case "$host" in
		i?86-*-mingw*)
			AC_CHECK_PROG(WINE, wine, wine)
			;;
		x86_64-*-mingw*)
			AC_CHECK_PROG(WINE, wine64, wine64)
			;;
	esac

	AS_IF([test x"$WINE" != x""], [
		AC_SUBST(RUN_TESTS, "run")
		AC_SUBST(WRAPPER, "$WINE")
	])

	AS_IF([test x"$with_wii" = x"yes"], [
		dnl Keep this lowercase, as WIILOAD is a variable used by
		dnl wiiload and thus likely already set by the user to something
		dnl that is not the path of the wiiload binary.
		AC_CHECK_PROG(wiiload, wiiload, wiiload)

		AS_IF([test x"$wiiload" != x""], [
			AC_SUBST(WRAPPER, "$wiiload")
		])
	])
], [
	AC_SUBST(RUN_TESTS, "run")
])

dnl We don't call AC_PROG_CPP, but only AC_PROG_OBJCPP and set CPP to OBJCPP
dnl and add OBJCPPFLAGS to CPPFLAGS, thus we need to AC_SUBST these ourself.
AC_SUBST(CPP)
AC_SUBST(CPPFLAGS)

AC_CONFIG_FILES([buildsys.mk extra.mk])
AC_OUTPUT
