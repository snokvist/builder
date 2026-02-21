################################################################################
#
# rtl88x2eu-openipc-greg
#
################################################################################

RTL88X2EU_OPENIPC_GREG_SITE = https://github.com/sickgreg/rtl88x2eu-apfpv.git
RTL88X2EU_OPENIPC_GREG_VERSION = ef22033f3b0361ee088d0f19a9701d9d46fb0ec0
RTL88X2EU_OPENIPC_GREG_SITE_METHOD = git
RTL88X2EU_OPENIPC_GREG_LICENSE = GPL-2.0
RTL88X2EU_OPENIPC_GREG_LICENSE_FILES = COPYING

RTL88X2EU_OPENIPC_GREG_MODULE_MAKE_OPTS = CONFIG_RTL8822EU=m \
	KVER=$(LINUX_VERSION_PROBED) \
	KSRC=$(LINUX_DIR)

$(eval $(kernel-module))
$(eval $(generic-package))
