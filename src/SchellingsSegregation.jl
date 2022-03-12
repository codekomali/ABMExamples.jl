# Copyright (c) 2022 Code Komali
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

using Agents
using Random
using InteractiveDynamics
# For non interactive CairoMakie is enough
# using CairoMakie
# For interactive plots use GLMakie
using GLMakie
using Statistics: mean 

mutable struct SchellingAgent <: AbstractAgent
    id::Int
    pos::NTuple{2,Int}
    mood::Bool
    group::Int
end

@agent SchellingAgentM GridAgent{2} begin
    mood::Bool
    group::Int
end

function initialize(;
    numagents = 320,
    griddims = (20,20),
    min_to_be_happy = 3,
    seed = 125
    )
    # define all parameters for the model
    space = GridSpace(griddims, periodic=false)
    properties = Dict(:min_to_be_happy => min_to_be_happy)
    rng = Random.MersenneTwister(seed)
    # create the model
    model = ABM(
        SchellingAgent,
        space;
        properties,
        rng,
        scheduler = Schedulers.randomly
    )
    # populate the model with Agents
    for n in 1:numagents
        agent = SchellingAgent(
            n, # id
            (1,1), # does not matter see add_agent_single!
            false, # mood
            n < numagents / 2 ? 1 : 2 # group-no
            )
        # adds the agent in a random empty location in the grid
        add_agent_single!(agent, model)
    end
    return model
end

function agent_step!(agent, model)
    minhappy = model.min_to_be_happy
    count_neighbors_same_group = 0
    # count the number of nearby neighbors belonging to same group
    for neighbor in nearby_agents(agent, model)
        if agent.group == neighbor.group
            count_neighbors_same_group += 1
        end
    end
    if count_neighbors_same_group ≥ minhappy
        agent.mood = true
    else
        move_agent_single!(agent, model)
    end
    return
end

# The agent data to collect each step
x(agent) = agent.pos[1]
adata = [(:mood, sum), (x, mean)]
alabels = ["happy", "avg. x"]

model = initialize(; numagents = 300)

groupcolor(a) = a.group == 1 ? :blue : :orange
groupmarker(a) = a.group == 1 ? :circle : :rect

# To create interactive application
parange = Dict(:min_to_be_happy => 0:8)

figure, adf, mdf = abm_data_exploration(
    model, agent_step!, dummystep, parange;
    ac = groupcolor, am = groupmarker, as = 10,
    adata, alabels
)
figure

# To generate a static plot of the model

# figure, _ = abm_plot(
#     model;
#     ac = groupcolor,
#     am = groupmarker,
#     as = 10
# )
# figure

# To generate a video (post processed) of the ABM

# abm_video(
#     "schelling.mp4",
#     model,
#     agent_step!;
#     ac = groupcolor,
#     am = groupmarker,
#     as = 10,
#     framerate = 4,
#     frames = 20,
#     title = "Schelling's segregation model"
# )