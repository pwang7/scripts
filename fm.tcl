fm_shell -f runme.fms | tee runme.log
formality
fm_shell -gui

set search_path ". ./lib ./netlists ./rtl"
.synopsys_fm.setup

# 1 read SVF from DC as guidance
set_svf default.svf
# 2 read RTL
read_verilog -r alu.v
# 3 read libraries, netlist
read_db -i lsi_10k.db
read_verilog -i alu.fast.vg
set_top -auto; # 自动设置顶层
# 4 match and verify
verify

# 保持DC和Formality设置一致
set synopsys_auto_setup true

# 读文件夹里所有Verilog代码
read_verilog -i top.gv -vcs "-y ./lib + libext+.v"

# 把DW的目录设为DC的目录
hdlin_dwroot


read_verilog -r TOP.v -vcs "
    -y <DIR_NAME>
    -v <FILE_NAME>
    +libext+<EXTENSION>
    +define+<MACRO>
    +incdir+<DIR_NAME>
    -f <FILE_LIST>
"

# 写之前必须set_top，建议match前保存
write_container -replace -r ref
# 读无须set_top
read_container -r ref.fsc

# 保留会话，下次重新打开恢复
save_session -replace mysession_file
restore_session mysession_file.fss