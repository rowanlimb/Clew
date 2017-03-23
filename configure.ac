AC_INIT([clew], [1.0], [rowan.limb@bt.com])
AM_INIT_AUTOMAKE([foreign])
m4_include([beeline-latency/m4/m4_ax_check_mysql.m4])
AC_CHECK_PROG([bash_shell], [bash], [bash],,,[/usr/sbin/bash])
AC_CHECK_PROG(SSH_CHECK, ssh, yes)
if test x"$SSH_CHECK" != x"yes"; then
  AC_MSG_ERROR([Please install ssh before installing AC_PACKAGE_NAME.])
fi
AC_CHECK_PROG(R_CHECK, R, yes)
if test x"$R_CHECK" != x"yes"; then
  AC_MSG_ERROR([Please install R before installing AC_PACKAGE_NAME.])
fi
AC_CHECK_PROG(SHINY_CHECK, shiny-server, yes)
if test x"$SHINY_CHECK" != x"yes"; then
  AC_MSG_ERROR([Please install Shiny Server before installing AC_PACKAGE_NAME.])
fi
AC_ARG_WITH([shinyapproot],
  [AS_HELP_STRING([--with-shinyapproot=PATH], [root dir for shiny-server app files])],
  [shinyapproot=$withval],
  [shinyapproot="/srv/shiny-server"])
AC_ARG_WITH([shinyappdir],
  [AS_HELP_STRING([--with-shinyappdir=DIR], [dir for dashboard files])],
  [shinyappdir="$shinyapproot/$withval"],
  [shinyappdir="$shinyapproot/AC_PACKAGE_NAME"])
AC_SUBST([shinyappdir], [$shinyappdir])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
