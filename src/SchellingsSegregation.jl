# Copyright (c) 2022 Code Komali
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
module SchellingExample

export run_schelling_model!

using Agents
using Random
using InteractiveDynamics 
using GLMakie
using Statistics: mean
using Dates 

mutable struct SchellingAgent <: AbstractAgent
    id::Int
    pos::NTuple{2,Int}
    mood::Bool
    group::Int
end

# This was causing some weird problem when I try to use
# it as part of a module.
# @agent SchellingAgent GridAgent{2} begin
#     mood::Bool
#     group::Int
# end

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

function video_filename(file_prefix)
    file_prefix * Dates.format(Dates.now(),"yymmddHHMMSS") * ".mp4"
end

function run_schelling_model!(total_ticks, file_prefix)
    # The agent data to collect each step
    x(agent) = agent.pos[1]
    adata = [(:mood, sum), (x, mean)]
    alabels = ["happy", "avg. x"]

    model = initialize(; numagents = 300)
    video_model = deepcopy(model)

    groupcolor(a) = a.group == 1 ? :blue : :orange
    groupmarker(a) = a.group == 1 ? :circle : :rect
    # A bit of a hack!
    # Unfortunately the abm_video does not allow us to record data
    # so, we are creating two copies of the same model and running
    # them one after the other. The same number of timesteps
    # as the model is deterministic because of the random-seed
    # repeated runs should be exactly same and produce same results
    data, _ = run!(model, agent_step!, total_ticks; adata)
    filename = video_filename(file_prefix)
    abm_video(
        filename,
        video_model,
        agent_step!;
        ac = groupcolor,
        am = groupmarker,
        as = 10,
        framerate = 4,
        frames = total_ticks + 1, # plus one to account for 0th frame
        title = "Schelling's segregation model",
        adata = adata,
        alabels = alabels,
        # There is a SPF (steps per frame param)
        # That defaults to 1 and should never be changed for this hack to make sense
    )
    return (data, filename)
end

# (data, _) = run_model!(20,"schelling")
# data

# To create interactive application
# parange = Dict(:min_to_be_happy => 0:8)

# figure, adf, mdf = abm_data_exploration(
#     model, agent_step!, dummystep, parange;
#     ac = groupcolor, am = groupmarker, as = 10,
#     adata, alabels
# )

# To generate a static plot of the model

# figure, _ = abm_plot(
#     model;
#     ac = groupcolor,
#     am = groupmarker,
#     as = 10
# )
# figure

# To generate a video (post processed) of the ABM

end