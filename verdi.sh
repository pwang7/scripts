#NOVAS_HOME
export SYNOPSYS_HOME=/usr/synopsys
export VERDI_HOME=$SYNOPSYS_HOME/verdi-L-2016.06-1
export LD_LIBRARY_PATH=$VERDI_HOME/share/PLI/VCS/LINUX64:$LD_LIBRARY_PATH
export PATH=$VERDI_HOME/bin:$PATH

$VCS_HOME/packages/sva_cg
$VCS_HOME/packages/aip
$VCS_HOME/doc/UserGuide/pdf/sva_checkerlib.pdf
$finish;$assertkill;

# 1） 如果只想生成​simv.daidir/kdb.elab++， VCS编译时，用”-lca -kdb=only“
# 2） 如果只想看部分层级的Hierarchy, ​ VCS编译时，用”-lca -kdb -top hierarchy“。如只关系top.a.b 这一级的RTL，可使用如下命令：”-lca -kdb -top top.a.b“
vcs -full64 -sverilog +v2k -debug_pp \
    -cm link+cond+fsm+tgl+branch \
    -P $VERDI_HOME/share/PLI/VCS/LINUX64/novas.tab $VERDI_HOME/share/PLI/VCS/LINUX64/pli.a \
    -R +fsdb+autoflush -l vcs.log \
    tb_seq.v detect.v
vcs -sverilog -debug_pp -LDFLAGS -rdynamic \
    -P $VERDI_HOME/share/PLI/VCS/LINUX64/novas.tab $VERDI_HOME/share/PLI/VCS/LINUX64/pli.a \
    -f tb_top.f +vcs+lic+wait -l compile.log

cat <<EOF >sim.f
../rtl/tb_bcd_to_7seg.v
../rtl/bcd_to_7seg.v
EOF
cat <<EOF >dump_fsdb_vcs.tcl
#global env
fsdbDumpfile "$::env(TOP_MODULE).fsdb"
fsdbDumpvars
run
#fsdbDumpoff
#fsdbDumpon
#run 200ns
EOF
fsdbDumpvars +fsdbfile+a.fsdb

vcs -kdb=shell -lca -fgp
vcs -sverilog -debug_pp +vcs+lic+wait \
    -P $VERDI_HOME/share/PLI/VCS/LINUX64/novas.tab $VERDI_HOME/share/PLI/VCS/LINUX64/pli.a \
    -l vcs.log -f sim.f
./simv -ucli -i dump_fsdb_vcs.tcl -l sim.log +fsdb+autoflush
./simv -verdi # Interactive mode
./simv -gui=verdi

verdi -cov -covdir merged.vdb
verdi -cov -covdir *.vdb -plan *.hvp # Coverage mode

verdi -sv -f sim.f -top $TOP_MODULE -ssf $TOP_MODULE.fsdb -nologo


verdi -dbdir <PATH TO>/simv.daidir 
verdi -dbdir <PATH TO>/simv.daidir -preload PRELOAD_FILE
verfi -ssf my.fsdb



vcs -sverilog -ntb_opts uvm-1.1 -debug_pp + vcs+vcdpluson -l compile.log +vcs+lic+wait -f file.list # +incdir+$UVM_HOME/src
./simv -l sim.log +ntb_random_seed=$SEED +UVM_TR_RECORD +UVM_LOG_RECORD + UVM_TESTNAME=test_base +UVM_VERBOSITY=UVM_HIGH +vcs+lic+wait

# Verdi trace X
export VERDI_TRACEX_ENABLE=1
export FSDB_GATE=0

cat <<EOF > signal.list
tb.M1#2000
tb.M2#2000
tb.M3#2000
EOF
traceX -ssf $TOP_MODULE.fsdb -signal_file signal.list -lca
verdi -lca -load_trace_report trx_report.txt

nCompare -fsdb A.fsdb -fsdb A_sdf.fsdb
nCompare -rule <RULE_FILE> -report <REPORT_FILE>

docker run --rm -it -p 5902:5902 \
    --hostname lizhen --mac-address 02:42:ac:11:00:02 \
    -v `pwd`:`pwd` -w `pwd` --entrypoint ./prerun.sh \
    phyzli/ubuntu18.04_xfce4_vnc4server_synopsys2016

ssvncviewer localhost:2 -scale 1.9

# Check version
vcs -ID
verdi -envinfo

# https://www.cnblogs.com/Chenrt/p/15107987.html
apt install libxft2 libxss1 # for GUI installer
apt install lsb-core # for lmgrd
apt install build-essential # for VCS
apt install libfreetype6 libxss1 libxft2 libxt6 libxmu6 libnuma1 # for Verdi
apt install libxi6 libxrandr2 libtiff5 libmng2 # for DC
ln -s /usr/lib/x86_64-linux-gnu/libtiff.so.5 /usr/lib/x86_64-linux-gnu/libtiff.so.3
ln -s /usr/lib/x86_64-linux-gnu/libmng.so.2 /usr/lib/x86_64-linux-gnu/libmng.so.1

vcs -full64 -LDFLAGS -Wl,--no-as-needed -cpp g++ -cc gcc +lint=TFIPC-L -override_timescale=1ns/1ps tb.v

docker run -it \
    -e USER=root \
    -e DEBIAN_FRONTEND=noninteractive \
    -e DISPLAY \
    -v /tmp/.X11-unix/:/tmp/.X11-unix/:ro \
    -v $HOME/.Xauthority:/root/.Xauthority:ro \
    --hostname `hostname` \
    --mac-address A4:DB:30:35:75:57 \
    -v `pwd`:/tmp/work \
    -v `realpath ~/Downloads/rust_cargo/rtl/apt`:/etc/apt \
    -w /tmp/work \
    ubuntu




# Ways to run Verdi:

vcs -full64 -file run_vcs.f
verdi -dbdir ./simv.daidir/

verdi -f run_verdi.f

vericom -f run_verdi.f
verdi -lib work

simv -verdi # interactive

simv
verdi -ssf novas.fsdb # post-processing mode

verdi -ssf novas.fsdb -dbdir ./my_simdata # when simv.dadir moved