using CSV
using DataFrames
using Dates
using TcpDevices

### Main functions

function run(;
    interval_s=5,
    nrepeats=3,
    dev1_add="127.0.0.1:5025",
    dev2_add="127.0.0.1:5026",
    vna1_dir=nothing,
    vna2_dir=nothing,
)
    today = Dates.format(Dates.now(), "yyyy-mm-dd")
    vna1_dir = @something vna1_dir joinpath(@__DIR__, today, "vna1")
    vna2_dir = @something vna2_dir joinpath(@__DIR__, today, "vna2")
    mkpath(vna1_dir)
    mkpath(vna2_dir)

    dev1, dev2 = setup_devices(; dev1_add, dev2_add)
    @info "Starting continuous measurements at $interval_s second intervals, with $nrepeats repeats (ctrl-c to stop)"
    try
        run_continuously(dev1, dev2, interval_s, nrepeats, vna1_dir, vna2_dir)
    finally
        close!(dev1)
        close!(dev2)
    end
    return
end

function single(;
    nrepeats=3,
    dev1_add="127.0.0.1:5025",
    dev2_add="127.0.0.1:5026",
    vna1_dir=nothing,
    vna2_dir=nothing,
)
    today = Dates.format(Dates.now(), "yyyy-mm-dd")
    vna1_dir = @something vna1_dir joinpath(@__DIR__, today, "vna1")
    vna2_dir = @something vna2_dir joinpath(@__DIR__, today, "vna2")
    mkpath(vna1_dir)
    mkpath(vna2_dir)

    dev1, dev2 = setup_devices(; dev1_add, dev2_add)
    @info "Collecting a single measurement on both VNAs with $nrepeats repeats"
    try
        dev1_files = pause_save_S11_S22(dev1, vna1_dir, nrepeats)
        dev2_files = pause_save_S11_S22(dev2, vna2_dir, nrepeats)
        return vcat(dev1_files, dev2_files)
    finally
        close!(dev1)
        close!(dev2)
    end
end

### Internals

function setup_devices(; dev1_add="127.0.0.1:5025", dev2_add="127.0.0.1:5026")
    @info "Initializing device 1 on $dev1_add"
    dev1 = initialize(TcpDevices.PicoVNA106, dev1_add)
    println(query(dev1, "*IDN?")) # info
    println()

    @info "Initializing device 2 on $dev2_add"
    dev2 = initialize(TcpDevices.PicoVNA106, dev2_add)
    println(query(dev2, "*IDN?")) # info
    println()

    return dev1, dev2
end

function run_continuously(
    dev1::TcpDevices.Instr{PicoVNA106},
    dev2::TcpDevices.Instr{PicoVNA106},
    interval_s::Real,
    nrepeats::Int,
    vna1_dir::String,
    vna2_dir::String,
)
    timer = Timer(0, interval=interval_s)
    while true
        t1 = @elapsed dev1_files = pause_save_S11_S22(dev1, vna1_dir, nrepeats)
        t2 = @elapsed dev2_files = pause_save_S11_S22(dev2, vna2_dir, nrepeats)
        @info "Collected measurements: vna1 $(length(dev1_files)) in $t1 seconds. vna2 $(length(dev2_files)) in $t2 seconds"
        wait(timer) # wait until next interval
    end
end

function pause_save_S11_S22(dev::TcpDevices.Instr{PicoVNA106}, dir::String, nrepeats::Int)
    query(dev, "ABOR")              # stop any ongoing measurements
    query(dev, "FORMAT ASCII")      # set data format to ASCII
    # clear_buffer(dev)

    files = String[]
    freqs = collect(get_freq_range(dev))
    for i in 1:nrepeats
        query(dev, "*TRG")          # trigger a single sweep
        df = DataFrame()
        df.freq = freqs
        df.S11_real = get_parse_vector_float(dev, "CALC:DATA S11,LOGMAG")
        df.S11_imag = get_parse_vector_float(dev, "CALC:DATA S11,PHASE")
        df.S22_real = get_parse_vector_float(dev, "CALC:DATA S22,LOGMAG")
        df.S22_imag = get_parse_vector_float(dev, "CALC:DATA S22,PHASE")

        dt_str = Dates.format(Dates.now(), "yyyy-mm-dd_HH-MM-SS")
        file = joinpath(dir, "$(dt_str).csv")
        CSV.write(file, df)
        push!(files, file)
    end
    return files
end

function get_parse_vector_float(dev::TcpDevices.Instr{PicoVNA106}, cmd::String)
    vec_string = query(dev, cmd)
    return [parse(Float64, s) for s in split(vec_string, ",")]
end

function get_freq_range(dev::TcpDevices.Instr{PicoVNA106})
    length = parse(Int, query(dev, "SENS:SWE:POIN?"))
    start = parse(Float64, split(query(dev, "SENS:FREQ:STAR?"), " MHz")[1])
    stop = parse(Float64, split(query(dev, "SENS:FREQ:STOP?"), " MHz")[1])
    return range(start, stop, length)
end

