
BUILD_TMP = build-tmp

nobase_pkgdata_SCRIPTS = \
	bin/spread-cs \
	bin/spread-ds \
	bin/spread-gw \
	bin/spreadcli \
	bin/spreadctl \
	bin/spreadtop \
	lib/spread-osd/default.rb \
	lib/spread-osd/log.rb \
	lib/spread-osd/command/cli.rb \
	lib/spread-osd/command/cs.rb \
	lib/spread-osd/command/ctl.rb \
	lib/spread-osd/command/ds.rb \
	lib/spread-osd/command/gw.rb \
	lib/spread-osd/command/top.rb \
	lib/spread-osd/lib/cclog.rb \
	lib/spread-osd/lib/ebus.rb \
	lib/spread-osd/lib/vbcode.rb \
	lib/spread-osd/logic/fault_detector.rb \
	lib/spread-osd/logic/membership.rb \
	lib/spread-osd/logic/node.rb \
	lib/spread-osd/logic/okey.rb \
	lib/spread-osd/logic/tsv_data.rb \
	lib/spread-osd/logic/weight.rb \
	lib/spread-osd/service/balance.rb \
	lib/spread-osd/service/base.rb \
	lib/spread-osd/service/bus.rb \
	lib/spread-osd/service/config.rb \
	lib/spread-osd/service/config_cs.rb \
	lib/spread-osd/service/config_ds.rb \
	lib/spread-osd/service/config_gw.rb \
	lib/spread-osd/service/data_client.rb \
	lib/spread-osd/service/data_server.rb \
	lib/spread-osd/service/data_server_url.rb \
	lib/spread-osd/service/gateway.rb \
	lib/spread-osd/service/gateway_ro.rb \
	lib/spread-osd/service/gw_http.rb \
	lib/spread-osd/service/heartbeat.rb \
	lib/spread-osd/service/master_select.rb \
	lib/spread-osd/service/mds.rb \
	lib/spread-osd/service/mds_tt.rb \
	lib/spread-osd/service/membership.rb \
	lib/spread-osd/service/process.rb \
	lib/spread-osd/service/rpc.rb \
	lib/spread-osd/service/rpc_cs.rb \
	lib/spread-osd/service/rpc_ds.rb \
	lib/spread-osd/service/rpc_gw.rb \
	lib/spread-osd/service/rts.rb \
	lib/spread-osd/service/rts_file.rb \
	lib/spread-osd/service/rts_memory.rb \
	lib/spread-osd/service/slave.rb \
	lib/spread-osd/service/stat.rb \
	lib/spread-osd/service/stat_cs.rb \
	lib/spread-osd/service/stat_ds.rb \
	lib/spread-osd/service/stat_gw.rb \
	lib/spread-osd/service/storage.rb \
	lib/spread-osd/service/storage_dir.rb \
	lib/spread-osd/service/sync.rb \
	lib/spread-osd/service/time_check.rb \
	lib/spread-osd/service/ulog.rb \
	lib/spread-osd/service/ulog_file.rb \
	lib/spread-osd/service/ulog_memory.rb \
	lib/spread-osd/service/weight.rb \
	lib/spread-osd/version.rb \
	test/01_add_get_remove.rt \
	test/02_read.rt \
	test/03_getd_readd.rt \
	test/04_version_time.rt \
	test/05_version_name.rt \
	test/06_http_get_set_remove_1.rt \
	test/07_http_get_set_remove_2.rt \
	test/08_read_only_time.rt \
	test/09_read_only_name.rt \
	test/chukan.rb \
	test/common.rb

bin_SCRIPTS = \
	$(BUILD_TMP)/spread-cs \
	$(BUILD_TMP)/spread-ds \
	$(BUILD_TMP)/spread-gw \
	$(BUILD_TMP)/spreadcli \
	$(BUILD_TMP)/spreadctl \
	$(BUILD_TMP)/spreadtop

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

HTML_DOCS = \
	doc/index.html \
	doc/index.ja.html \
	doc/api.html \
	doc/api.ja.html \
	doc/arch.html \
	doc/arch.ja.html \
	doc/build.html \
	doc/build.ja.html \
	doc/command.html \
	doc/command.ja.html \
	doc/devel.html \
	doc/devel.ja.html \
	doc/faq.html \
	doc/faq.ja.html \
	doc/fault.html \
	doc/fault.ja.html \
	doc/howto.html \
	doc/howto.ja.html \
	doc/howto/nginx.html \
	doc/howto/nginx.ja.html \
	doc/install.html \
	doc/install.ja.html \
	doc/operation.html \
	doc/operation.ja.html

MOSTLYCLEANFILES = \
	$(bin_SCRIPTS) \
	$(HTML_DOCS)

.md.html:
	ruby doc/erbdoc.rb $< $@.tmp
	mv $@.tmp $@

doc/index.html: README.md
	ruby doc/erbdoc.rb $< $@.tmp
	mv $@.tmp $@

doc/index.ja.html: README.ja.md
	ruby doc/erbdoc.rb $< $@.tmp
	mv $@.tmp $@

$(HTML_DOCS): doc/erbdoc.rb doc/doc.erb

htmldoc: $(HTML_DOCS)

