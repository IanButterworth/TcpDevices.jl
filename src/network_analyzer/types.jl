"""
- [`PicoTechNetworkAnalyzer`](@ref)
"""
abstract type NetworkAnalyzer <: Instrument end

"""
Supported models
- `PicoVNA106`
- `PicoVNA108`

Supported functions
- [`initialize`](@ref)
- [`terminate`](@ref)


- [`get_impedance`](@ref)
- [`get_impedance_analyzer_info`](@ref)
- [`set_measurement_to_complex`](@ref)
- [`set_measurement_to_impedance_and_phase`](@ref)
- [`get_channel`](@ref)
- [`set_channel`](@ref)


- [`is_average_mode_on`](@ref)
- [`get_num_averages`](@ref)
- [`get_sweep_direction`](@ref)
- [`get_point_delay_time`](@ref)
- [`get_sweep_delay_time`](@ref)
- [`get_frequency_limits`](@ref)
- [`set_frequency_limits`](@ref)
- [`get_frequency`](@ref)
- [`get_num_data_points`](@ref)
- [`set_num_data_points`](@ref)
- [`get_volt_dc`](@ref)
- [`set_volt_dc`](@ref)
- [`get_volt_ac`](@ref)
- [`set_volt_ac`](@ref)
- [`get_bandwidth`](@ref)
- [`set_bandwidth`](@ref)
"""
abstract type PicoTechNetworkAnalyzer <: NetworkAnalyzer end
struct PicoVNA106 <: PicoTechNetworkAnalyzer end
struct PicoVNA108 <: PicoTechNetworkAnalyzer end

struct NetworkAnalyzerInfo
    dc_voltage::Unitful.Voltage
    ac_voltage::Unitful.Voltage
    num_averages::Int64
    bandwidth_level::Int64
    point_delay_time::Unitful.Time
    sweep_delay_time::Unitful.Time
    sweep_direction::String
end

struct NetworkAnalyzerData
    info::Union{NetworkAnalyzerInfo, Nothing}
    frequency::Vector{typeof(1.0u"Hz")}
    impedance::Vector{typeof((1.0+1.0im)*u"Ω")}
end

function Base.show(io::IO, data::NetworkAnalyzerData)
    show(data.info)
    println(io, "frequency: ", size(data.frequency), " ", unit(data.frequency[1]))
    println(io, "impedance: ", size(data.impedance), " ", unit(data.impedance[1]))
end

function Base.show(io::IO, info::NetworkAnalyzerInfo)
    println(io, "NetworkAnalyzerInfo: ")
    for fieldname in fieldnames(typeof(info))
        println(io, "  " * String(fieldname) * ": ", getfield(info, fieldname))
    end
end
