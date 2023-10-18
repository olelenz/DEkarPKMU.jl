function solve_model(Optimizer)
    model = Model(Optimizer);

    # variables of the model
    
    @variable(model, EAC);  # total annualised cost of the energy systems
    @variable(model, CAPEX >= 0);  # investments
    @variable(model, NPV_CF >= 0);  # net present value of the yearly cash flows
    @variable(model, NPV_ReInv >= 0);  # net present value of the reinvestments
    @variable(model, NPV_ResV >= 0);  # net present value of the residual values
    @variable(model, CRF >= 0);  # capital recovery factor

    # objective of the model
    @objective(model, Min, EAC);
    
    # constraints of the model
   # @constraint(model, EAC == (CAPEX - NPV_CF + NPV_ReInv - NPV_ResV) * CRF);  # calculating EAC
    print("in here ");
    return 1;
end
