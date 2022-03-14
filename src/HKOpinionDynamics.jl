# Copyright (c) 2022 Code Komali
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

module HKOpinionDynamicsExample

export hk_model_run_and_plot!

using Agents
using Statistics: mean
using Plots
using Random

mutable struct HKAgent <: AbstractAgent
    id::Int
    old_opinion::Float64
    new_opinion::Float64
    previous_opinion::Float64
end

function hk_model(; numagents = 100, ϵ = 0.2)
    model = ABM(HKAgent, scheduler = Schedulers.fastest, properties= Dict(:ϵ => ϵ))
    Random.seed!(1234)
    for i in 1:numagents
        o = rand()
        add_agent!(model, o, o, -1)
    end
    return model
end

function boundfilter(agent, model)
    filter(
        j -> abs(agent.old_opinion -j) < model.ϵ,
        [a.old_opinion for a in allagents(model)]
    )
end

function agent_step!(agent, model)
    agent.previous_opinion = agent.old_opinion
    agent.new_opinion = mean(boundfilter(agent, model))
end

function model_step!(model)
    for a in allagents(model)
        a.old_opinion = a.new_opinion
    end
end

function terminate(model, s)
    if any(
        !isapprox(a.previous_opinion, a.new_opinion; rtol= 1e-12) for a in allagents(model)
    )
        return false
    else
        return true
    end
end

function model_run(; kwargs...)
    model = hk_model(; kwargs...)
    agent_data,_ = run!(
        model,
        agent_step!,
        model_step!,
        terminate;
        adata = [:new_opinion],
        # make sure to comment the 'when' otherwise you won't get the graph as expected
        #when = terminate # when to collect data, the default is to collect on every step
    )
    return agent_data
end

#data = model_run()

plotsim(data, ϵ) = plot(
    data.step,
    data.new_opinion,
    leg = false,
    group = data.id,
    title = "epsilon = $(ϵ)",
)


function hk_model_run_and_plot!(eps_list=[0.05, 0.15, 0.3] ; kwargs...)
    plots = []
    alldata = []
    for eps in eps_list
        data = model_run(; ϵ = eps)
        push!(alldata, data)
        plt = plotsim(data, eps)
        push!(plots, plt)
    end
    plot(plots..., layout=(3,1))
    savefig("HKOpinionDynamicsPlot.png")
    return alldata
end

#hk_model_run_and_plot!()


end

