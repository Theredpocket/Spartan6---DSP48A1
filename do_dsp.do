vlib work
vlog DSP2.v DSP48A1_tb.v PipelineRegister.v
vsim -voptargs=+acc work.DSP48A1_tb
add wave *
run -all