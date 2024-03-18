using TcpDevice
using DataFrames
using CSV

function run(; interval_s=5, nmeas=3, dev1_add="127.0.0.1:5025", dev2_add="127.0.0.1:5026")
    dev1 = initialize(TcpDevice.PicoVNA106, dev1_add)
    @info "Initialized device 1 on $dev1_add" dev1
    dev2 = initialize(TcpDevice.PicoVNA106, dev2_add)
    @info "Initialized device 2 on $dev1_add" dev2
    @info "Starting continuous measurements (ctrl-c to stop)" interval_s nmeas
    run_continuously(dev1, dev2, interval_s, nmeas)
end

function run_continuously(
            dev1::PicoTechNetworkAnalyzer,
            dev2::PicoTechNetworkAnalyzer,
            interval_s::Float64,
            nmeas::Int,
        )
    dir1 = joinpath(@__DIR__, "vna1")
    dir2 = joinpath(@__DIR__, "vna2")
    timer = Timer(0, interval=interval_s)
    try
        while true
            dev1_files = pause_save_S11_S22(dev1, dir1, nmeas)
            dev2_files = pause_save_S11_S22(dev2, dir2, nmeas)
            @info "Collected measurements" length(dev1_files) length(dev2_files)
            wait(timer) # wait until next interval
        end
    catch e
        e isa InterruptException || rethrow()
    end
end


function pause_save_S11_S22(dev::PicoTechNetworkAnalyzer, dir::String, nmeas::Int)
    query(dev, "ABOR")              # stop any ongoing measurements
    query(dev, "FORMAT ASCII")      # set data format to ASCII
    clear_buffer(dev)

    files = String[]
    freqs = collect(get_freq_range(dev))
    for i in 1:nmeas
        query(dev, "*TRG")          # trigger a single sweep
        df = DataFrame(freq=Float64[], S11_real=Float64[], S11_imag=Float64[], S22_real=Float64[], S22_imag=Float64[])
        df[!, :freq] = freqs
        df[!, :S11_real] = get_parse_vector_float(dev, "CALC:DATA S11,LOGMAG")
        df[!, :S11_imag] = get_parse_vector_float(dev, "CALC:DATA S11,PHASE")
        df[!, :S22_real] = get_parse_vector_float(dev, "CALC:DATA S22,LOGMAG")
        df[!, :S22_imag] = get_parse_vector_float(dev, "CALC:DATA S22,PHASE")
        dt = Dates.now()
        dt_str = Dates.format(dt, "yyyy-mm-dd_HH-MM-SS")
        file = joinpath(dir, "$(dt_str).csv")
        CSV.write(file, df)
        push!(files, file)
    end
    return files
end

function get_parse_vector_float(dev::PicoTechNetworkAnalyzer, cmd::String)
    vec_string = query(dev, cmd)
    return [parse(Float64, s) for s in split(vec_string, ",")]
end

function get_freq_range(dev::PicoTechNetworkAnalyzer)
    length = parse(Int, query(dev, "SENS:SWE:POIN?"))
    start = parse(Float64, query(dev, "SENS:FREQ:STAR?"))
    stop = parse(Float64, query(dev, "SENS:FREQ:STOP?"))
    return range(start, stop, length)
end

