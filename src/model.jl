#using .DEkarPKMU  # take out to use this file outside the module
function solve_model(optimizer, data::Data)
    model = Model(optimizer);

    set_optimizer_attributes(model, "MIPGap" => 0.07, "TimeLimit" => 25200, "PreSOS2BigM" => 1500);  # time limit was at 25200
    set_optimizer_attribute(model, "NonConvex", 2)  # For quadratic Constraints.  With setting 2, non-convex quadratic problems are solved by means of translating them into bilinear form and applying spatial branching
    set_optimizer_attribute(model, "MIPFocus", 2)  # MIPFocus = 1: good quality feasible solutions; MIPFocus = 2: attention on proving optimality; MIPFocus = 3:  If the best objective bound is moving very slowly (focus on the bound)


    
    # Parameter
    Capacity_cost_PV = [data.capacity_cost_PV1, data.capacity_cost_PV2, data.capacity_cost_PV3];
    Capacity_cost_WT = [data.capacity_cost_WT1, data.capacity_cost_WT2, data.capacity_cost_WT3];
    OPEX_pv0 = [data.OPEX_PV1, data.OPEX_PV2, data.OPEX_PV3];
    Capacity_cost_bat = [data.capacity_cost_bat1, data.capacity_cost_bat2, data.capacity_cost_bat3, data.capacity_cost_bat4, data.capacity_cost_bat5, data.capacity_cost_bat6];
    
    # variables

    Breakpoints = [1,2,3,4];
    B = length(Breakpoints);
    Breakpoints_1 = [1,2,3,4];
    Z = length(Breakpoints_1);

    # variables of the model
    
    #VARIABLES
    #Electricity
    @variable(model, Total_demand >=0)           # Total demand over period P [kWh]
    @variable(model, Total_PV_GEN >=0)           # Total PV generation over period P [kWh]
    @variable(model, Total_WT_GEN >=0)           # Total WT generation over period P [kWh]
    @variable(model, Total_buy >=0)              # Total energy purchased [kWh]
    @variable(model, Total_sell >=0)             # Total energy sold [kWh]
    # return -1;  # request gurobi license while on campus
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

    #Maximum values
    @constraint(model, c_bat <= 100000)
    @constraint(model, c_EL <= 100000)
    @constraint(model, c_H <= 100000)
    @constraint(model, c_FC <= 100000)
    @constraint(model, c_heat_exchanger_EL <= 100000)
    @constraint(model, c_heat_exchanger_FC <= 100000)
    @constraint(model, [p=1:data.p], E_sold[p] <= 100000)
    @constraint(model, [p=1:data.p], E_purchased[p] <= 100000)
   
    # HESS constraints 
    @constraint(model, [p=1:data.p], data.h_min*c_H <= H[p]) ;                          # hydrogen tank capacity  
    @constraint(model, [p=1:data.p], H[p] <= data.h_max*c_H);                           # hydrogen tank capacity
    @constraint(model, [p=1:data.p], c_H >= H[p]/(data.h_max*100)*100)                  # Capacity of H2 tank
    @constraint(model, [p=1], H[p] == data.h_init*c_H + EL_output[p] - R_FC[p]);   # first period hydrogen balance    
    @constraint(model, [p=2:data.p], H[p] == H[p-1] + EL_output[p] - R_FC[p]);     # hydrogen balance    
    @constraint(model, [p=data.p], H[p] == data.h_init*c_H);                            # last period hydrogen balance   
    @constraint(model, Invest_H == c_H*data.capacity_cost_H)
 
    @constraint(model, [p=1:data.p], EL_output[p] <= c_EL); # electrolyzer capacity    
    @constraint(model, [p=1:data.p], FC_output[p] <= c_FC); # fuel cell capacity    
    
    @constraint(model, r_EL .== data.ellf .* c_EL);
    @constraint(model, [p=1:data.p], EL_output[p] == sum(V[z,p]*data.f_z[z]*R_EL[p] for z=1:Z));
    @constraint(model, r_FC .== data.fclf .* c_FC);                                                  # "real" fuel cell load [kW]                  
    @constraint(model, [p=1:data.p], FC_output[p] == sum(Λ[b,p]*data.f_x[b]*R_FC[p] for b=1:B));
    
    @constraint(model, [p=1:data.p], sum(Λ[b,p] for b=1:B) == 1);                    #sos2 constraint 1: Breakpoints must sum up to 1    
    @constraint(model, [p=1:data.p], Λ[1:B,p] in MOI.SOS2([1.0,2.0,3.0,4.0]));       #sos2 constraint 2: Only 2 adjacent Breakpoints can be >0       
    @constraint(model, [p=1:data.p], FC_output[p] == sum(Λ[b,p]*r_FC[b] for b=1:B)); #sos2 constraint 3: Fuel Cell Input calculation 

    @constraint(model, [p=1:data.p], sum(V[z,p] for z=1:Z) == 1);                    #sos2 constraint 1: Breakpoints must sum up to 1    
    @constraint(model, [p=1:data.p], V[1:Z,p] in MOI.SOS2([1.0,2.0,3.0,4.0]));       #sos2 constraint 2: Only 2 adjacent Breakpoints can be >0       
    @constraint(model, [p=1:data.p], EL_output[p] == sum(V[z,p]*r_EL[z] for z=1:Z)); #sos2 constraint 3: Electrolyzer Input calculation 
   
    @constraint(model, [p=1:data.p], used_heat_FC[p] <= R_FC[p] * data.waste_heat_FC * data.eta_heat_exchanger); # usable heat is heat output of fuel cell multiplied with efficiency
    @constraint(model, [p=1:data.p], used_heat_FC[p] <= c_heat_exchanger_FC);                        # usable heat is lower or same as capacity of heat exchanger
    @constraint(model, Invest_heat_exchanger_FC == c_heat_exchanger_FC * data.capacity_cost_heat_exchanger)
    @constraint(model, OPEX_heat_exchanger_FC == c_heat_exchanger_FC * data.OPEX_fix_heat_exchanger + sum(used_heat_FC[x]*data.OPEX_var_heat_exchanger for x=1:data.p))
    @constraint(model, [p=1:data.p], used_heat_EL[p] <= R_EL[p] * data.waste_heat_EL * data.eta_heat_exchanger); # usable heat is heat output of fuel cell multiplied with efficiency
    @constraint(model, [p=1:data.p], used_heat_EL[p] <= c_heat_exchanger_EL);                        # usable heat is lower or same as capacity of heat exchanger
    @constraint(model, Invest_heat_exchanger_EL == c_heat_exchanger_EL * data.capacity_cost_heat_exchanger)
    @constraint(model, OPEX_heat_exchanger_EL == c_heat_exchanger_EL * data.OPEX_fix_heat_exchanger + sum(used_heat_EL[x]*data.OPEX_var_heat_exchanger for x=1:data.p))
    
    @constraint(model, [p=1:data.p], max_E_purchased >= E_purchased[p])                              # max. amount of purchased energy in one period
    
    @constraint(model, [p=1:data.p], data.edem[p] + E_sold[p] + R_EL[p] + R_Bat_in[p] 
        == E_purchased[p] + data.re_PV[p]*c_PV + data.re_WT[p]*c_WT + FC_output[p] + R_Bat_out[p]*data.eta_bat_out); # energy balance constraint    
    
    @constraint(model, EC >= (NPV_annual_costs + Invest_tot - Residual)*data.CRF_project);                   # energy cost calculation (In Invest_tot also NPVs of replacement costs)

    @constraint(model, OPEX_tot >= OPEX_PV/8760*data.p + OPEX_WT + data.OPEX_bat/100*Invest_bat/8760*data.p + data.OPEX_H/100*Invest_H/8760*data.p + data.OPEX_EL/100*Invest_EL/8760*data.p + data.OPEX_FC/100*Invest_FC/8760*data.p + 
    OPEX_heat_exchanger_FC/8760*data.p + OPEX_heat_exchanger_EL/8760*data.p)
    @constraint(model, Invest_tot >= (Invest_PV/8760*data.p) + (Invest_WT/8760*data.p) + Invest_bat/8760*data.p*data.repl_factor_bat_NPV + Invest_H/8760*data.p + 
    Invest_EL/8760*data.p*data.repl_factor_EL_NPV + Invest_FC/8760*data.p*data.repl_factor_FC_NPV + Invest_heat_exchanger_FC/8760*data.p + Invest_heat_exchanger_EL/8760*data.p)
    @constraint(model, Annual_costs >= (OPEX_tot + sum(E_purchased[p]*data.beta_buy[p] for p=1:data.p) + max_E_purchased*data.beta_buy_LP - sum(E_sold[p]*data.beta_sell[p] for p=1:data.p) - sum(used_heat_EL[p]*data.heat_price for p=1:data.p)-sum(used_heat_FC[p]*data.heat_price for p=1:data.p)))
    @constraint(model, NPV_annual_costs >= sum((Annual_costs*((1+data.inflation)^t)/((1+data.WACC)^t)) for t=1:20))   
    @constraint(model, Residual <= data.residualValue_PV*Invest_PV/8760*data.p + data.residualValue_WT*Invest_WT/8760*data.p + data.residualValue_bat*Invest_bat/8760*data.p + data.residualValue_EL*Invest_EL/8760*data.p + data.residualValue_FC*Invest_FC/8760*data.p + data.residualValue_H*Invest_H/8760*data.p + data.residualValue_heat_exchanger*((Invest_heat_exchanger_EL/8760*data.p)+(Invest_heat_exchanger_FC/8760*data.p)))
        
    

    # PV capacity constraints including investment decision and OPEX calculation (including scale effects)
    @constraint(model, sum(i)==1)       
    @constraint(model, Invest_PV == sum(i[a]*Capacity_cost_PV[a] for a=1:3)*c_PV)
    @constraint(model, OPEX_PV == sum(i[a]*OPEX_pv0[a] for a=1:3)*c_PV)
    @constraint(model, c_PV >= i[3]*1000)
    @constraint(model, c_PV >= i[2]*30)
    @constraint(model, c_PV >= i[1]*0)                                     
    @constraint(model, c_PV <= data.max_capa_PV)

    # WT capacity constraints including investment decision and OPEX calculation (including scale effects)                
    @constraint(model, sum(k)==1)  
    @constraint(model, Invest_WT == sum(k[h]*Capacity_cost_WT[h] for h=1:3)*c_WT)
    @constraint(model, c_WT >= k[3]*1000)     #  >= 1000 kW
    @constraint(model, c_WT >= k[2]*100)      # 100 kW - 1000 kW
    @constraint(model, c_WT >= k[1]*0)        # < 100 kW
    @constraint(model, c_WT <= data.max_capa_WT)
    @constraint(model, OPEX_WT == c_WT*data.OPEX_WT_fix/8760*data.p + sum(data.re_WT[x]*c_WT*data.OPEX_WT_var for x=1:data.p))

    # Electrolyzer constraints including investment decision
    @constraint(model, Invest_EL == c_EL*data.capacity_cost_EL)

    # Fuel cell constraints including investment decision
    @constraint(model, Invest_FC == c_FC*data.capacity_cost_FC)

    # Battery capacity constraints including investment decision
    @constraint(model, sum(j)==1)
    @constraint(model, Invest_bat == sum(j[d]*Capacity_cost_bat[d] for d=1:6)*c_bat)
    @constraint(model, c_bat >= j[6]*1000)
    @constraint(model, c_bat >= j[5]*250)
    @constraint(model, c_bat >= j[4]*30)  
    @constraint(model, c_bat >= j[3]*10)
    @constraint(model, c_bat >= j[2]*5)
    @constraint(model, c_bat >= j[1]*0)
    @constraint(model, [p=1:data.p], SOC[p] >= (data.SOC_min * c_bat))                                                                # battery SOC
    @constraint(model, [p=1:data.p], SOC[p] <= (data.SOC_max * c_bat))                                                                # battery SOC
    @constraint(model, [p=1], SOC[p] == data.SOC_init*c_bat + data.eta_bat_in*R_Bat_in[p] - R_Bat_out[p]);                              # battery balance in first period
    @constraint(model, [p=2:data.p], SOC[p] == SOC[p-1] + data.eta_bat_in*R_Bat_in[p] - R_Bat_out[p] - (SOC[p-1]*data.self_discharge/100));  # battery balance    
    @constraint(model, [p=data.p], SOC[p] == data.SOC_init*c_bat);                                                                    # last period battery balance


    @constraint(model, Total_demand == sum(data.edem[p] for p=1:data.p))
    @constraint(model, Total_PV_GEN == sum(data.re_PV[p]*c_PV for p=1:data.p))
    @constraint(model, Total_WT_GEN == sum(data.re_WT[p]*c_WT for p=1:data.p))  
    @constraint(model, Total_buy == sum(E_purchased[p] for p=1:data.p))  
    @constraint(model, Total_sell == sum(E_sold[p] for p=1:data.p))  


    #OPTIMIZE model
    optimize!(model);
    return model;
end
