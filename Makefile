#openmeshbr dashboard

include $(TOPDIR)/rules.mk

PKG_NAME:=dashmesh
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_REV:=r1
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=git://github.com/mcellos/dashmesh.git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_BUILD_DIR:=$(BUILD_DIR)/dashmesh-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/dashmesh
        SECTION:=admin
        CATEGORY:=Administration
        TITLE:=sistema de gestão para redes mesh digital
        DEPENDS:=+libjson
endef

define Package/dashmesh/description
        sistema de gestão para redes mesh digital
endef
define Package/afrimesh-dashboard/install
	$(INSTALL_DIR)  $(1)/etc
	$(INSTALL_DIR)  $(1)/etc/config
	$(INSTALL_DIR)  $(1)/www/afrimesh
	$(INSTALL_DIR)  $(1)/www/cgi-bin
	$(INSTALL_DIR)  $(1)/www/afrimesh/images
	$(INSTALL_DIR)  $(1)/www/afrimesh/javascript
	$(INSTALL_DIR)  $(1)/www/afrimesh/javascript/jquery
	$(INSTALL_DIR)  $(1)/www/afrimesh/javascript/openlayers
	$(INSTALL_DIR)  $(1)/www/afrimesh/style/images
	$(INSTALL_DIR)  $(1)/www/afrimesh/style
	$(INSTALL_DIR)  $(1)/www/afrimesh/modules

	$(INSTALL_CONF) ./files/etc/config/afrimesh $(1)/etc/config
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/dashboard/www/index.html             $(1)/www/afrimesh/index.html
	$(INSTALL_BIN)  $(PKG_BUILD_DIR)/dashboard/cgi-bin/ajax-proxy.cgi     $(1)/www/cgi-bin
	$(INSTALL_BIN)  $(PKG_BUILD_DIR)/dashboard/cgi-bin/mesh-topology.kml  $(1)/www/cgi-bin
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/dashboard/www/images/*.gif           $(1)/www/afrimesh/images
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/dashboard/www/images/*.png           $(1)/www/afrimesh/images
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/dashboard/javascript/jquery/*        $(1)/www/afrimesh/javascript/jquery
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/dashboard/javascript/openlayers/*    $(1)/www/afrimesh/javascript/openlayers
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/dashboard/javascript/afrimesh*.js    $(1)/www/afrimesh/javascript
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/dashboard/www/modules/*.html         $(1)/www/afrimesh/modules
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/dashboard/www/modules/*.js           $(1)/www/afrimesh/modules
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/dashboard/www/style/*.css            $(1)/www/afrimesh/style
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/dashboard/www/style/images/*.gif     $(1)/www/afrimesh/style/images
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/dashboard/www/style/images/*.png     $(1)/www/afrimesh/style/images
endef


$(eval $(call BuildPackage,dashmesh))
