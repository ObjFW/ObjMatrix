SUBDIRS = src tests
DISTCLEAN = aclocal.m4		\
	    autom4te.cache	\
	    buildsys.mk		\
	    config.h		\
	    config.log		\
	    config.status	\
	    extra.mk

include buildsys.mk
include extra.mk

tests: src

install-extra:
	i=ObjMatrix.oc; \
	packagesdir="${DESTDIR}$$(${OBJFW_CONFIG} --packages-dir)"; \
	${INSTALL_STATUS}; \
	if ${MKDIR_P} $$packagesdir && ${INSTALL} -m 644 $$i $$packagesdir/$$i; then \
		${INSTALL_OK}; \
	else \
		${INSTALL_FAILED}; \
	fi

uninstall-extra:
	i=ObjMatrix.oc; \
	packagesdir="${DESTDIR}$$(${OBJFW_CONFIG} --packages-dir)"; \
	if test -f $$packagesdir/$$i; then \
		if rm -f $$packagesdir/$$i; then \
			${DELETE_OK}; \
		else \
			${DELETE_FAILED}; \
		fi \
	fi; \
	rmdir $$packagesdir >/dev/null 2>&1 || true
