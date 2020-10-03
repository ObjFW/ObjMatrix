include ../../extra.mk

STATIC_PIC_LIB_NOINST = ${EXCEPTIONS_LIB_A}
STATIC_LIB_NOINST = ${EXCEPTIONS_A}

SRCS = MTXClientException.m			\
       MTXFetchRoomListFailedException.m	\
       MTXJoinRoomFailedException.m		\
       MTXLeaveRoomFailedException.m		\
       MTXLoginFailedException.m		\
       MTXLogoutFailedException.m
INCLUDES = ${SRCS:.m=.h}

include ../../buildsys.mk

CPPFLAGS += -I. -I..

