include("./Agilent4294A.jl")
include("./Agilent4395A.jl")

set_num_data_points(i::Instr{T}, n) where (T <: ImpedanceAnalyzer) =
    write(obj, "POIN $n")

get_num_data_points(i::Instr{T}) where (T <: ImpedanceAnalyzer) =
    query(obj, "POIN?")

get_volt_dc(obj::Instr{T}) where (T <: ImpedanceAnalyzer) =
    query(obj, "DCV?")

set_volt_dc!(obj::Instr{T}, num) where (T <: ImpedanceAnalyzer) =
    write(obj, "DCV $num")

get_volt_limit_dc(obj::Instr{T}) where (T <: ImpedanceAnalyzer) =
    query(obj, "MAXDCV?")

set_volt_limit_dc!(i::Instr{T}, v) where (T <: ImpedanceAnalyzer) =
    write(i, "MAXDCV $v")

