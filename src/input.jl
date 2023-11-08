mutable struct Data
    p::Int64
    edem::Vector{Real}
    beta_buy::Vector{Float64}
    beta_sell::Vector{Float64}
    re_PV::Vector{Float64}
    re_WT::Vector{Float64}

    WACC::Float64
    inflation::Float64
    CRF_project::Float64

    beta_buy_LP::Float64
    heat_price::Float64

    h_min::Float64
    h_max::Float64
    h_init::Float64
    eff_H::Int64
    capacity_cost_H::Float64
    OPEX_H::Int64

    capacity_cost_EL::Int64
    OPEX_EL::Float64
    waste_heat_EL::Float64
    repl_factor_EL_NPV::Float64

    capacity_cost_FC::Int64
    OPEX_FC::Int64
    waste_heat_FC::Float64
    repl_factor_FC_NPV::Float64

    capacity_cost_PV1::Int64
    capacity_cost_PV2::Int64
    capacity_cost_PV3::Int64
    capacity_cost_WT1::Int64
    capacity_cost_WT2::Int64
    capacity_cost_WT3::Int64

    OPEX_PV1::Float64
    OPEX_PV2::Float64
    OPEX_PV3::Float64
    OPEX_WT_fix::Int64
    OPEX_WT_var::Float64

    residualValue_PV::Float64
    residualValue_WT::Float64
    residualValue_bat::Float64
    residualValue_EL::Float64
    residualValue_H::Float64
    residualValue_FC::Float64
    residualValue_heat_exchanger::Float64

    capacity_cost_bat1::Int64
    capacity_cost_bat2::Int64
    capacity_cost_bat3::Int64
    capacity_cost_bat4::Int64
    capacity_cost_bat5::Int64
    capacity_cost_bat6::Int64
    OPEX_bat::Int64
    SOC_min::Float64
    SOC_max::Float64
    SOC_init::Float64
    eta_bat_in::Float64
    eta_bat_out::Float64
    max_duration::Int64
    self_discharge::Float64
    repl_factor_bat_NPV::Float64

    capacity_cost_heat_exchanger::Float64
    OPEX_fix_heat_exchanger::Int64
    OPEX_var_heat_exchanger::Float64
    eta_heat_exchanger::Float64

    max_capa_PV::Float64
    max_capa_WT::Float64

    fclf::Vector{Float64}
    f_x::Vector{Float64}

    ellf::Vector{Float64}
    f_z::Vector{Float64}
    
    Data() = new()
end
JSON3.StructType(::Type{Data}) = JSON3.Mutable();

function dataToJSON(data::Data)::String
    return JSON3.write(data); 
end

function JSONToData(json::String)::Data
    return JSON3.read(json, Data);
end


function initDataXLSX(file::String)::Data
    data::Data = Data()
    
    x::XLSX.XLSXFile = XLSX.readxlsx(file)

    l_epb::XLSX.Worksheet = x["eur_purchase"];             # Energy purchase prices per hour (incl. grid fees per kWh, taxes, levies)
    l_eps::XLSX.Worksheet = x["eur_sale"];                 # Energy selling price
    l_rfc::XLSX.Worksheet = x["Fuelcell"];                 # Fuelcell details
    l_periods::XLSX.Worksheet = x["p"];                    # Periods
    l_ed::XLSX.Worksheet = x["Load_Profiles_Industry_1h"]; # Demand (Load profile)
    l_rg_PV::XLSX.Worksheet = x["rg_PV"];                  # Renewable generation (PV) per kW
    l_rg_WT::XLSX.Worksheet= x["rg_WT"];                  # Renewable generation (Wind Turbine) per kW
    l_tank::XLSX.Worksheet = x["Tank"];                    # H2 Tank details              
    l_a_PV::XLSX.Worksheet = x["PV"];                      # PV system details
    l_a_WT::XLSX.Worksheet = x["WT"];                      # Wind Turbine (WT) details
    l_elec::XLSX.Worksheet = x["Electrolyzer"];            # Electrolyzer details
    l_battery::XLSX.Worksheet = x["Battery"];              # Technical and economic battery details
    l_heat_ex::XLSX.Worksheet = x["heat_exchanger"];       # Technical and economic details of plate heat exchanger
    l_general::XLSX.Worksheet = x["General_Company_Data"]; # General Input Data
    
    data.p = length(l_periods[:]);                   # P
    data.edem = [l_ed[r,5] for r in 9:(8+data.p)]   # energy demand in period p
    data.beta_buy = [l_epb[q,13] for q in 6:(5+data.p)] # energy purchase prices in period p [€/kWh]
    data.beta_sell = [l_eps[q,1] for q in 35:34+data.p]; # energy selling prices in period p
    data.re_PV = vec(Float64.(l_rg_PV[:]));# renewable generation (PV) in period p per installed kW
    data.re_WT = vec(Float64.(l_rg_WT[:]));# renewable generation (Wind Turbine) in period p per installed kW

    #HESS parameter
    data.WACC = Float64.(l_general[5,2])           # WACC as factor
    data.inflation = Float64.(l_general[6,2])      # Inflation as factor
    data.CRF_project = Float64.(l_general[11,2])   # CRF of project
    
    data.beta_buy_LP = Float64.(l_epb[6,14])          # Grid fee -> power price [€/kW]
    data.heat_price = Float64.(l_elec[19,2]);      # Heat price for "Fernwärme" [€/kWh_th]

    data.h_min = Float64.(l_tank[4,2]);            # min tank fill state 
    data.h_max = Float64.(l_tank[5,2]);            # max tank fill state 
    data.h_init = Float64.(l_tank[3,2]);           # initial tank fill (begin & end)
    data.eff_H = Int64.(l_tank[7,2]);              # efficiency of H2 tank
    data.capacity_cost_H = Float64.(l_tank[10,2]); # capacity cost for H2 tank per kWh storage [€/kWh]
    data.OPEX_H = Int64.(l_tank[11,2]);            # OPEX for H2 tank in percentage of CAPEX
    
    data.capacity_cost_EL = Int64.(l_elec[3,2]);      # Capacity cost of electrolyzer [€/kW]
    data.OPEX_EL = Float64.(l_elec[6,2]);             # OPEX of electrolyzer [% of CAPEX per year]
    data.waste_heat_EL = Float64.(l_elec[7,2]);       # Waste heat from electrolyzer [kWh_th / kWh_el electricity input]
    data.repl_factor_EL_NPV = Float64.(l_elec[23,2])  # Replacement factor because lifetime < projecttime (Results in replacement + Invest NPV when multiplying with CAPEX)

    data.capacity_cost_FC = Int64.(l_rfc[11,2]);      # Capacity cost of fuel cell [€/kW]
    data.OPEX_FC = Int64.(l_rfc[14,2]);               # OPEX of fuel cell [% of CAPEX per year]
    data.waste_heat_FC = Float64.(l_rfc[15,2]);       # Waste heat from fuel cell [kWh_th / kWh_H2 input]
    data.repl_factor_FC_NPV = Float64.(l_rfc[19,2])   # Replacement factor because lifetime < projecttime (Results in replacement + Invest NPV when multiplying with CAPEX)
   
    data.capacity_cost_PV1 = Int64.(l_a_PV[4,2])      # Capacity cost for PV system < 30 kW [€/kW]
    data.capacity_cost_PV2 = Int64.(l_a_PV[4,3])      # Capacity cost for PV system < 1000 kW [€/kW]
    data.capacity_cost_PV3 = Int64.(l_a_PV[4,4])      # Capacity cost for PV system > 1000 kW [€/kW]
    data.capacity_cost_WT1 = Int64.(l_a_WT[2,2])      # Capacity cost for WT system < 100 [€/kW]
    data.capacity_cost_WT2 = Int64.(l_a_WT[2,3])      # Capacity cost for WT system < 1000 kW [€/kW]
    data.capacity_cost_WT3 = Int64.(l_a_WT[2,4])      # Capacity cost for WT system > 1000 kW [€/kW]
    
    data.OPEX_PV1 = Float64.(l_a_PV[5,2])           # Annual OPEX for PV system < 30 kW [€/kW]
    data.OPEX_PV2 = Float64.(l_a_PV[5,3])           # Annual OPEX for PV system < 1000 kW [€/kW]
    data.OPEX_PV3 = Float64.(l_a_PV[5,4])           # Annual OPEX for PV system > 1000 kW [€/kW]
    data.OPEX_WT_fix = Int64.(l_a_WT[5,2])          # Fix OPEX cost WT [€/kW]
    data.OPEX_WT_var = Float64.(l_a_WT[6,2])        # Variable OPEX cost WT [€/kWh]
    
    data.residualValue_PV = Float64.(l_a_PV[18,2])                   # Factor to multiply with Investment to get NPV of residual value
    data.residualValue_WT = Float64.(l_a_WT[14,2])                   # Factor to multiply with Investment to get NPV of residual value
    data.residualValue_bat = Float64.(l_battery[30,2])               # Factor to multiply with Investment to get NPV of residual value
    data.residualValue_EL = Float64.(l_elec[25,2])                   # Factor to multiply with Investment to get NPV of residual value
    data.residualValue_H = Float64.(l_tank[17,2])                    # Factor to multiply with Investment to get NPV of residual value
    data.residualValue_FC = Float64.(l_rfc[21,2])                    # Factor to multiply with Investment to get NPV of residual value
    data.residualValue_heat_exchanger = Float64.(l_heat_ex[12,2])    # Factor to multiply with Investment to get NPV of residual value

    data.capacity_cost_bat1 = Int64.(l_battery[5,2])  # Capacity cost for battery system < 5 kWh [€/kWh]
    data.capacity_cost_bat2 = Int64.(l_battery[6,2])  # Capacity cost for battery system < 10 kWh [€/kWh]
    data.capacity_cost_bat3 = Int64.(l_battery[7,2])  # Capacity cost for battery system < 30 kWh [€/kWh]
    data.capacity_cost_bat4 = Int64.(l_battery[8,2])  # Capacity cost for battery system < 250 kWh [€/kWh]
    data.capacity_cost_bat5 = Int64.(l_battery[9,2])  # Capacity cost for battery system < 1000 kWh [€/kWh]
    data.capacity_cost_bat6 = Int64.(l_battery[10,2]) # Capacity cost for battery system > 1000 kWh [€/kWh]
    data.OPEX_bat = Int64.(l_battery[23,2])               # OPEX of battery [% of CAPEX per year]
    data.SOC_min = Int64.(l_battery[14,2])/100            # Minimum SOC of battery [%]
    data.SOC_max = Int64.(l_battery[15,2])/100            # Maximum SOC of battery [%]
    data.SOC_init = Int64.(l_battery[13,2])/100           # Initial SOC of battery [%]
    data.eta_bat_in = Int64.(l_battery[18,2])/100           # Charging Efficiency [%]
    data.eta_bat_out = Int64.(l_battery[19,2])/100          # Discharging Efficiency [%]
    data.max_duration = Int64.(l_battery[16,2])           # max. duration energy can be stored in battery (battery = short-term storage)
    data.self_discharge = Float64.(l_battery[21,2])       # self-discharge factor of battery per hour      
    data.repl_factor_bat_NPV = Float64.(l_battery[28,2])  # Replacement factor because lifetime < projecttime (Results in replacement + Invest NPV when multiplying with CAPEX)

    data.capacity_cost_heat_exchanger = Float64.(l_heat_ex[4,2])  # Capacity cost for heat exchanger [€/kW]
    data.OPEX_fix_heat_exchanger = Int64.(l_heat_ex[5,2])         # Fix OPEX heat exchanger [€/kW]
    data.OPEX_var_heat_exchanger = Float64.(l_heat_ex[6,2])       # Variable OPEX heat exchanger [€/kWh]
    data.eta_heat_exchanger = Float64.(l_heat_ex[8,2])/100          # Efficiency of heat exchanger

    data.max_capa_PV = Float64.(l_a_PV[16,2])                     # Maximum PV capacity [kW]
    data.max_capa_WT = Float64.(l_a_WT[12,2])                     # Maximum WT capacity [kW]

    #sos2 parameters for efficiency calculation of fuel cell -> Efficiency Breakpoints of load & efficiency (Nonlinearity - 4 Breakpoints)
    data.fclf = [Float64.(l_rfc[2,1]), Float64.(l_rfc[3,1]), Float64.(l_rfc[4,1]), Float64.(l_rfc[5,1])]; # fuel cell load factor [%]                                 -> x-axis [%]                                                                   
    data.f_x = [Float64.(l_rfc[2,2]), Float64.(l_rfc[3,2]), Float64.(l_rfc[4,2]), Float64.(l_rfc[5,2])];  # fuel cell efficiency factor in breakpoints [%]            -> y-axis [%]
                                                                                                                    
    data.ellf = [Float64.(l_elec[12,1]), Float64.(l_elec[13,1]), Float64.(l_elec[14,1]), Float64.(l_elec[15,1])]; # electrolyzer load factor [%]                      -> x-axis [%]
    data.f_z = [Float64.(l_elec[12,2]), Float64.(l_elec[13,2]), Float64.(l_elec[14,2]), Float64.(l_elec[15,2])];  # electrolyzer efficiency factor in breakpoints [%] -> y-axis [%]

    return data
end
