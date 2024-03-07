function solve_model_var(optimizer, data::Data)
    model = Model(optimizer);

    Breakpoints = [1,2,3,4];
    B = length(Breakpoints);
    Breakpoints_1 = [1,2,3,4];
    Z = length(Breakpoints_1);

    @variable(model, Total_demand >=0)           
    @variable(model, Total_PV_GEN >=0)           
    @variable(model, Total_WT_GEN >=0)           
    @variable(model, Total_buy >=0)              
    @variable(model, Total_sell >=0)             
    @variable(model, E_sold[1:data.p] >= 0);          
    @variable(model, E_purchased[1:data.p] >= 0);     
    @variable(model, max_E_purchased >=0);              
    @variable(model, EC);                        
   
    @variable(model, c_PV >=0)
    @variable(model, Invest_PV >=0)
    @variable(model, OPEX_PV >=0)

    @variable(model, c_WT >=0)
    @variable(model, Invest_WT >=0)
    @variable(model, OPEX_WT >=0)

    @variable(model, c_bat >=0)
    @variable(model, Invest_bat >=0)
    @variable(model, R_Bat_in[1:data.p] >= 0);   
    @variable(model, R_Bat_out[1:data.p] >= 0);  
    @variable(model, SOC[1:data.p] >= 0);        

    @variable(model, c_EL >= 0);            
    @variable(model, Invest_EL >= 0);       
    @variable(model, R_EL[1:data.p] >= 0);       
    @variable(model, c_FC >= 0);            
    @variable(model, r_FC[1:B] >= 0);       
    @variable(model, r_EL[1:Z] >= 0);       
    @variable(model, Invest_FC >= 0);       
    @variable(model, R_FC[1:data.p] >= 0);       
    @variable(model, c_H >= 0);             
    @variable(model, H[1:data.p] >= 0);          
    @variable(model, Invest_H >=0)          
    @variable(model, Λ[1:B,1:data.p] >= 0);      
    @variable(model, V[1:Z,1:data.p] >= 0);      
    @variable(model, FC_output[1:data.p] >=0);   
    @variable(model, EL_output[1:data.p] >=0);   
    
    @variable(model, used_heat_FC[1:data.p] >=0)         
    @variable(model, c_heat_exchanger_FC >=0)       
    @variable(model, Invest_heat_exchanger_FC >=0)   
    @variable(model, OPEX_heat_exchanger_FC >=0)     
    @variable(model, used_heat_EL[1:data.p] >=0)         
    @variable(model, c_heat_exchanger_EL >=0)       
    @variable(model, Invest_heat_exchanger_EL >=0)  
    @variable(model, OPEX_heat_exchanger_EL >=0)    

    @variable(model, NPV_annual_costs)
    @variable(model, OPEX_tot >=0)
    @variable(model, Invest_tot >=0)
    @variable(model, Annual_costs)
    @variable(model, Residual >=0)
    
    @objective(model, Min, EC); 

    if(data.usage_PV)
        @constraint(model, Invest_PV == data.capacity_cost_PV2 * c_PV);
        @constraint(model, c_PV >= 30);
        @constraint(model, c_PV <= data.max_capa_PV)
        @constraint(model, OPEX_PV == data.OPEX_PV2*c_PV)
    else
        @constraint(model, Invest_PV <= 0);
        @constraint(model, c_PV == 0);
        @constraint(model, OPEX_PV == 0);
    end
    
    if(data.usage_WT)
        @constraint(model, Invest_WT == data.capacity_cost_WT2 * c_WT);
        @constraint(model, c_WT >= 100);
        @constraint(model, c_WT <= data.max_capa_WT)
        @constraint(model, OPEX_WT == c_WT*data.OPEX_WT_fix/8760*data.p + sum(data.re_WT[x]*c_WT*data.OPEX_WT_var for x=1:data.p))
    else
        @constraint(model, Invest_WT <= 0);
        @constraint(model, c_WT == 0);
        @constraint(model, OPEX_WT == 0)
    end

    if(data.usage_H)
        @constraint(model, c_H <= 100000)

        @constraint(model, [p=1:data.p], data.h_min*c_H <= H[p]) ;                            
        @constraint(model, [p=1:data.p], H[p] <= data.h_max*c_H);                           
        @constraint(model, [p=1:data.p], c_H >= H[p]/(data.h_max*100)*100)                  
        @constraint(model, [p=1], H[p] == data.h_init*c_H + EL_output[p] - R_FC[p]);       
        @constraint(model, [p=2:data.p], H[p] == H[p-1] + EL_output[p] - R_FC[p]);         
        @constraint(model, [p=data.p], H[p] == data.h_init*c_H);                               
        @constraint(model, Invest_H == c_H*data.capacity_cost_H)

        @constraint(model, c_EL <= 100000)
        @constraint(model, c_FC <= 100000)
        @constraint(model, c_heat_exchanger_EL <= 100000)
        @constraint(model, c_heat_exchanger_FC <= 100000)

        @constraint(model, [p=1:data.p], EL_output[p] <= c_EL);     
        @constraint(model, [p=1:data.p], FC_output[p] <= c_FC);     

        @constraint(model, Invest_EL == c_EL*data.capacity_cost_EL)

        @constraint(model, Invest_FC == c_FC*data.capacity_cost_FC)

        @constraint(model, [p=1:data.p], used_heat_FC[p] <= R_FC[p] * data.waste_heat_FC * data.eta_heat_exchanger); 
        @constraint(model, [p=1:data.p], used_heat_FC[p] <= c_heat_exchanger_FC);                        
        @constraint(model, Invest_heat_exchanger_FC == c_heat_exchanger_FC * data.capacity_cost_heat_exchanger)
        @constraint(model, OPEX_heat_exchanger_FC == c_heat_exchanger_FC * data.OPEX_fix_heat_exchanger + sum(used_heat_FC[x]*data.OPEX_var_heat_exchanger for x=1:data.p))
        @constraint(model, [p=1:data.p], used_heat_EL[p] <= R_EL[p] * data.waste_heat_EL * data.eta_heat_exchanger); 
        @constraint(model, [p=1:data.p], used_heat_EL[p] <= c_heat_exchanger_EL);                        
        @constraint(model, Invest_heat_exchanger_EL == c_heat_exchanger_EL * data.capacity_cost_heat_exchanger)
        @constraint(model, OPEX_heat_exchanger_EL == c_heat_exchanger_EL * data.OPEX_fix_heat_exchanger + sum(used_heat_EL[x]*data.OPEX_var_heat_exchanger for x=1:data.p))

    else
        @constraint(model, c_H <= 0)
        @constraint(model, [p=1:data.p], H[p] == 0);         

        @constraint(model, Invest_H == 0)

        @constraint(model, c_EL <= 0)
        @constraint(model, c_FC <= 0)
        @constraint(model, c_heat_exchanger_EL <= 0)
        @constraint(model, c_heat_exchanger_FC <= 0)

        @constraint(model, [p=1:data.p], EL_output[p] <= 0);     
        @constraint(model, [p=1:data.p], FC_output[p] <= 0);     

        @constraint(model, Invest_EL == 0)

        @constraint(model, Invest_FC == 0)

        @constraint(model, [p=1:data.p], used_heat_FC[p] <= 0);                               
        @constraint(model, Invest_heat_exchanger_FC == 0)
        @constraint(model, OPEX_heat_exchanger_FC == 0)
        @constraint(model, [p=1:data.p], used_heat_EL[p] <= 0);                        
        @constraint(model, Invest_heat_exchanger_EL == 0)
        @constraint(model, OPEX_heat_exchanger_EL == 0)
    end
    
    if(data.usage_bat)
        @constraint(model, c_bat <= 100000)
        @constraint(model, Invest_bat == data.capacity_cost_bat3*c_bat);
        @constraint(model, c_bat >= 10);
        @constraint(model, [p=1:data.p], SOC[p] >= (data.SOC_min * c_bat))                                                                
        @constraint(model, [p=1:data.p], SOC[p] <= (data.SOC_max * c_bat))                                                                
        @constraint(model, [p=1], SOC[p] == data.SOC_init*c_bat + data.eta_bat_in*R_Bat_in[p] - R_Bat_out[p]);                              
        @constraint(model, [p=2:data.p], SOC[p] == SOC[p-1] + data.eta_bat_in*R_Bat_in[p] - R_Bat_out[p] - (SOC[p-1]*data.self_discharge/100));      
        @constraint(model, [p=data.p], SOC[p] == data.SOC_init*c_bat);                                                                    
    else
        @constraint(model, c_bat == 0)
        @constraint(model, Invest_bat == 0);
        @constraint(model, [p=1:data.p], SOC[p] == 0);      
    end

    @constraint(model, [p=1:data.p], E_sold[p] <= 100000)
    @constraint(model, [p=1:data.p], E_purchased[p] <= 100000)
   
    @constraint(model, r_EL .== data.ellf .* c_EL);
    @constraint(model, r_FC .== data.fclf .* c_FC);                                                                    
    
    @constraint(model, [p=1:data.p], max_E_purchased >= E_purchased[p])                              
    
    @constraint(model, [p=1:data.p], data.edem[p] + E_sold[p] + R_EL[p] + R_Bat_in[p] 
        == E_purchased[p] + data.re_PV[p]*c_PV + data.re_WT[p]*c_WT + FC_output[p] + R_Bat_out[p]*data.eta_bat_out);     
    
    @constraint(model, EC >= (NPV_annual_costs + Invest_tot - Residual)*data.CRF_project);                   

    @constraint(model, OPEX_tot >= OPEX_PV/8760*data.p + OPEX_WT + data.OPEX_bat/100*Invest_bat/8760*data.p + data.OPEX_H/100*Invest_H/8760*data.p + data.OPEX_EL/100*Invest_EL/8760*data.p + data.OPEX_FC/100*Invest_FC/8760*data.p + 
    OPEX_heat_exchanger_FC/8760*data.p + OPEX_heat_exchanger_EL/8760*data.p)
    @constraint(model, Invest_tot >= (Invest_PV/8760*data.p) + (Invest_WT/8760*data.p) + Invest_bat/8760*data.p*data.repl_factor_bat_NPV + Invest_H/8760*data.p + 
    Invest_EL/8760*data.p*data.repl_factor_EL_NPV + Invest_FC/8760*data.p*data.repl_factor_FC_NPV + Invest_heat_exchanger_FC/8760*data.p + Invest_heat_exchanger_EL/8760*data.p)
    @constraint(model, Annual_costs >= (OPEX_tot + sum(E_purchased[p]*data.beta_buy[p] for p=1:data.p) + max_E_purchased*data.beta_buy_LP - sum(E_sold[p]*data.beta_sell[p] for p=1:data.p) - sum(used_heat_EL[p]*data.heat_price for p=1:data.p)-sum(used_heat_FC[p]*data.heat_price for p=1:data.p)))
    @constraint(model, NPV_annual_costs >= sum((Annual_costs*((1+data.inflation)^t)/((1+data.WACC)^t)) for t=1:20))   
    @constraint(model, Residual <= data.residualValue_PV*Invest_PV/8760*data.p + data.residualValue_WT*Invest_WT/8760*data.p + data.residualValue_bat*Invest_bat/8760*data.p + data.residualValue_EL*Invest_EL/8760*data.p + data.residualValue_FC*Invest_FC/8760*data.p + data.residualValue_H*Invest_H/8760*data.p + data.residualValue_heat_exchanger*((Invest_heat_exchanger_EL/8760*data.p)+(Invest_heat_exchanger_FC/8760*data.p)))
        
    @constraint(model, Total_demand == sum(data.edem[p] for p=1:data.p))
    @constraint(model, Total_PV_GEN == sum(data.re_PV[p]*c_PV for p=1:data.p))
    @constraint(model, Total_WT_GEN == sum(data.re_WT[p]*c_WT for p=1:data.p))  
    @constraint(model, Total_buy == sum(E_purchased[p] for p=1:data.p))  
    @constraint(model, Total_sell == sum(E_sold[p] for p=1:data.p))  

    optimize!(model); 
    return model;
end
