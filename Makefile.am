
AUTOMAKE_OPTIONS=foreign
bin_SCRIPTS = beeline-latency/src/log_remote_beeline_latency.sh beeline-latency/src/clusterconfig
CLEANFILES = dashboard/config.yml $(bin_SCRIPTS) beeline-latency/crontab_file

shinyapp_DATA = dashboard/config.yml dashboard/config_utils.R dashboard/server.R \
                dashboard/tabBox.tabpanel.BeelineLatencyObj.R dashboard/tabBox.tabpanel.DashboardObj.R \
                dashboard/tabBox.tabpanel.HistServerObj.R dashboard/tabBox.tabpanel.MetricsObj.R \
	        dashboard/tabBox.tabpanel.QueueWaitObj.R dashboard/tabBox.tabpanel.YarnMonObj.R \
                dashboard/tabBox.tabpanel.YarnObj.R dashboard/ui.R dashboard/restart.txt

EXTRA_DIST = dashboard/config.yml.template

dashboard/config.yml: Makefile
	./configureScript dashboard

beeline-latency/crontab_file:
	@echo '#Crontab file. Edit as required then run "crontab $@"' > $@
	@echo '*/5 * * * * ${bindir}/log_remote_beeline_latency.sh >/dev/null 2>&1' >> $@

beeline-latency/src/log_remote_beeline_latency.sh: dashboard/config.yml beeline-latency/src/log_remote_beeline_latency.in beeline-latency/crontab_file Makefile
	./configureScript beeline

clean-local: clean-local-check
.PHONY: clean-local-check
clean-local-check:
	-rm -rf beeline-latency/clusterscripts/*

distclean-local: distclean-local-check
.PHONY: distclean-local-check
distclean-local-check:
	-rm -rf beeline-latency/clusterscripts



