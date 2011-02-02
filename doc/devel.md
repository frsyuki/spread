Debugging and Improvement - SpreadOSD
=====================================

TODO

## Source tree

    lib/spread-osd
    |
    +-- lib/                    Fundamental libraries
    |   |
    |   +-- ebus.rb             EventBus
    |   +-- cclog.rb            Logging library
    |   +-- vbcode.rb           Variable byte code
    |
    +-- logic/
    |   |
    |   +-- node.rb             Definition of the Node class
    |   +-- okey.rb             Definition of the ObjectKey class
    |   +-- tsv_data.rb         Base class to use tab separated values
    |   +-- fault_detector.rb   Fault detector
    |   +-- membership.rb       Node list and replication-set list
    |   +-- weight.rb           Load balancing feature
    |
    +-- service/
    |   |
    |   +-- base.rb
    |   +-- bus.rb
    |   |
    |   +-- process.rb
    |   |
    |   +-- heartbeat.rb
    |   +-- sync.rb
    |   +-- time_check.rb
    |   |
    |   +-- membership.rb
    |   +-- master_select.rb
    |   +-- balance.rb
    |   +-- weight.rb
    |   |
    |   +-- data_client.rb
    |   +-- data_server.rb
    |   +-- data_server_url.rb
    |   +-- slave.rb
    |   |
    |   +-- gateway.rb
    |   +-- gateway_ro.rb
    |   +-- gw_http.rb
    |   |
    |   +-- config.rb
    |   +-- config_cs.rb
    |   +-- config_ds.rb
    |   +-- config_gw.rb
    |   |
    |   +-- stat.rb
    |   +-- stat_cs.rb
    |   +-- stat_ds.rb
    |   +-- stat_gw.rb
    |   |
    |   +-- rpc.rb
    |   +-- rpc_cs.rb
    |   +-- rpc_ds.rb
    |   +-- rpc_gw.rb
    |   |
    |   +-- rts.rb
    |   +-- rts_file.rb
    |   +-- rts_memory.rb
    |   |
    |   +-- ulog.rb
    |   +-- ulog_file.rb
    |   +-- ulog_memory.rb
    |   |
    |   +-- mds.rb
    |   +-- mds_tt.rb
    |   |
    |   +-- storage.rb
    |   +-- storage_dir.rb
    |
    +-- command/
    |   |
    |   +-- ctl.rb              Control tool
    |   +-- cs.rb               CS main
    |   +-- ds.rb               DS main
    |   +-- gw.rb               GW main
    |   +-- cli.rb              Command line client program
    |
    +-- default.rb              Some constants like default port number
    |
    +-- log.rb
    |
    +-- version.rb

