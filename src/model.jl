#using .DEkarPKMU  # take out to use this file outside the module
function solve_model(optimizer, data::Data)
    model = Model(optimizer);

    # variables

    CRF = 1;  # capital recovery factor

    # variables of the model
    
    #VARIABLES
    #Electricity
    @variable(model, Total_demand >=0)           # Total demand over period P [kWh]
    @variable(model, Total_PV_GEN >=0)           # Total PV generation over period P [kWh]
    @variable(model, Total_WT_GEN >=0)           # Total WT generation over period P [kWh]
    @variable(model, Total_buy >=0)              # Total energy purchased [kWh]
    @variable(model, Total_sell >=0)             # Total energy sold [kWh]
    return -1;  # request gurobi license while on campus
    @variable(model, E_sold[1:data.p] >= 0);          # not-negative: p Energy sold in kWh/period in period p
    @variable(model, E_purchased[1:data.p] >= 0);     # not-negative: p Energy purchased in kWh/period in period p
    @variable(model, max_E_purchased >=0);       # max. purchased energy per period       
    @variable(model, EC);                        # total energy cost
   
    @variable(model, i[1:3], Bin)                # Decision variable for scale effects on investment and OPEX
    @variable(model, c_PV >=0)
    @variable(model, Invest_PV >=0)
    @variable(model, OPEX_PV >=0)

    @variable(model, k[1:3], Bin)                # Decision variable for scale effects on investment and OPEX
    @variable(model, c_WT >=0)
    @variable(model, Invest_WT >=0)
    @variable(model, OPEX_WT >=0)

    @variable(model, j[1:6], Bin)
    @variable(model, c_bat >=0)
    @variable(model, Invest_bat >=0)
    @variable(model, R_Bat_in[1:data.p] >= 0);   # power consumed to charge the battery
    @variable(model, R_Bat_out[1:data.p] >= 0);  # power offered by discharging the battery
    @variable(model, SOC[1:data.p] >= 0);        # battery state of charge (SOC)

    #Hydrogen
    @variable(model, c_EL >= 0);            # capacity of electrolyzer
    @variable(model, Invest_EL >= 0);       # Investment for electrolyzer
    @variable(model, R_EL[1:data.p] >= 0);       # power consumption of electrolyzer
    @variable(model, c_FC >= 0);            # capacity of fuel cell
    @variable(model, r_FC[1:B] >= 0);       # for capacity calculation of fuel cell
    @variable(model, r_EL[1:Z] >= 0);       # for capacity calculation of electrolyzer
    @variable(model, Invest_FC >= 0);       # Investment for fuel cell
    @variable(model, R_FC[1:data.p] >= 0);       # hydrogen consumption of fuel cell (in kWh)
    @variable(model, c_H >= 0);             # hydrogen tank capacity
    @variable(model, H[1:data.p] >= 0);          # hydrogen tank fill
    @variable(model, Invest_H >=0)          # Investment for hydrogen tank
    @variable(model, Λ[1:B,1:data.p] >= 0);      # Λ for linear Interpolation of efficiency curve of fuel cell
    @variable(model, V[1:Z,1:data.p] >= 0);      # V for linear Interpolation of efficiency curve of electrolyzer
    @variable(model, FC_output[1:data.p] >=0);   # Fuel cell output
    @variable(model, EL_output[1:data.p] >=0);   # Electrolyzer output
    
    @variable(model, used_heat_FC[1:data.p] >=0)         # heat used/sold and generated from fuel cell
    @variable(model, c_heat_exchanger_FC >=0)       # heat used/sold and generated from fuel cell
    @variable(model, Invest_heat_exchanger_FC >=0)  # Investment for heat exchanger at the fuel cell 
    @variable(model, OPEX_heat_exchanger_FC >=0)    # Investment for heat exchanger at the fuel cell 
    @variable(model, used_heat_EL[1:data.p] >=0)         # heat used/sold and generated from electrolyzer
    @variable(model, c_heat_exchanger_EL >=0)       # heat used/sold and generated from electrolyzer
    @variable(model, Invest_heat_exchanger_EL >=0)  # Investment for heat exchanger at the electrolyzer
    @variable(model, OPEX_heat_exchanger_EL >=0)    # Investment for heat exchanger at the electrolyzer

    @variable(model, NPV_annual_costs)
    @variable(model, OPEX_tot >=0)
    @variable(model, Invest_tot >=0)
    @variable(model, Annual_costs)
    @variable(model, Residual >=0)
    
    #OBJECTIVE function
    @objective(model, Min, EC); 

    # objective of the model
    
    return 1;
end
