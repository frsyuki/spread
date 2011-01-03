
BUILD_TMP = build-tmp

nobase_pkgdata_SCRIPTS = \
	bin/spread-cs \
	bin/spread-ds \
	bin/spread-gw \
	bin/spreadcli \
	bin/spreadctl \
	lib/spread-osd/bus.rb \
	lib/spread-osd/common.rb \
	lib/spread-osd/default.rb \
	lib/spread-osd/command/cs.rb \
	lib/spread-osd/command/cli.rb \
	lib/spread-osd/command/ctl.rb \
	lib/spread-osd/command/ds.rb \
	lib/spread-osd/command/gw.rb \
	lib/spread-osd/lib/cclog.rb \
	lib/spread-osd/lib/ebus.rb \
	lib/spread-osd/lib/vbcode.rb \
	lib/spread-osd/logic/fault_detector.rb \
	lib/spread-osd/logic/master_storage_manager.rb \
	lib/spread-osd/logic/membership.rb \
	lib/spread-osd/logic/node.rb \
	lib/spread-osd/logic/slave_storage_manager.rb \
	lib/spread-osd/logic/storage_manager.rb \
	lib/spread-osd/logic/weight.rb \
	lib/spread-osd/mds/astt.rb \
	lib/spread-osd/mds/base.rb \
	lib/spread-osd/mds/tokyotyrant.rb \
	lib/spread-osd/rlog/base.rb \
	lib/spread-osd/rlog/file.rb \
	lib/spread-osd/rlog/memory.rb \
	lib/spread-osd/service/base.rb \
	lib/spread-osd/service/config.rb \
	lib/spread-osd/service/cs_config.rb \
	lib/spread-osd/service/cs_rpc.rb \
	lib/spread-osd/service/cs_status.rb \
	lib/spread-osd/service/ds_config.rb \
	lib/spread-osd/service/ds_rpc.rb \
	lib/spread-osd/service/ds_status.rb \
	lib/spread-osd/service/gateway.rb \
	lib/spread-osd/service/gw_config.rb \
	lib/spread-osd/service/gw_rpc.rb \
	lib/spread-osd/service/gw_status.rb \
	lib/spread-osd/service/heartbeat.rb \
	lib/spread-osd/service/mds.rb \
	lib/spread-osd/service/membership.rb \
	lib/spread-osd/service/net.rb \
	lib/spread-osd/service/status.rb \
	lib/spread-osd/service/storage.rb \
	lib/spread-osd/service/storage_client.rb \
	lib/spread-osd/service/timer.rb \
	lib/spread-osd/storage/base.rb \
	lib/spread-osd/storage/file.rb \
	lib/spread-osd/storage/hash.rb \
	lib/spread-osd/ulog/array.rb \
	lib/spread-osd/ulog/base.rb \
	lib/spread-osd/ulog/file.rb \
	lib/spread-osd/version.rb

bin_SCRIPTS = \
	$(BUILD_TMP)/spread-cs \
	$(BUILD_TMP)/spread-ds \
	$(BUILD_TMP)/spread-gw \
	$(BUILD_TMP)/spreadcli \
	$(BUILD_TMP)/spreadctl

EXTRA_DIST = \
	$(nobase_pkgdata_SCRIPTS) \
	Rakefile \
	VERSION \
	README.md \
	README.ja.md

$(bin_SCRIPTS):
	mkdir -p `dirname $@`
	$(RUBY) -e "puts '#!'+File.expand_path('`which $(RUBY)`')" > "$@.tmp"
	echo "\$$LOAD_PATH << '$(pkgdatadir)/lib'" >> "$@.tmp"
	echo "load '$(pkgdatadir)/bin/`basename $@`'" >> "$@.tmp"
	chmod 755 "$@.tmp"
	mv "$@.tmp" "$@"

.PHONY: $(bin_SCRIPTS)

MOSTLYCLEANFILES = \
	$(bin_SCRIPTS)

