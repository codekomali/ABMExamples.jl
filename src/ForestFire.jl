# Copyright (c) 2022 Code Komali
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

module ForestFireExample

export run_forest_fire_model!

using Agents
using Random
using Plots
using InteractiveDynamics
using CairoMakie

mutable struct Tree <: AbstractAgent
    id::Int
    pos::Dims{2}
    status::Symbol
end

function forest_fire(;
    density = 0.7,
    griddims = (100, 100)
)
    space = GridSpace(griddims; periodic = false, metric = :euclidean)
    forest = AgentBasedModel(Tree, space)
    # density is a probabilty of whether to add a tree
    for position in positions(forest)
        if rand() < density
            state = position[1] == 1 ? :burning : :green
            add_agent!(position, forest, state)
        end
    end
    return forest
end

function tree_step!(tree, forest)
    # the current tree is burning
    if tree.status == :burning
        # Find all green
        for neighbor in nearby_agents(tree, forest)
            if neighbor.status == :green
                neighbor.status = :burning
            end
        end
        tree.status = :burnt
    end
    return nothing
end

function burnt_percentage(m)
    burntTrees = count(t -> t.status == :burnt, allagents(m))
    totArea = length(positions(m))
    return burntTrees / totArea
end

function treecolor(a)
    if a.status == :burning
        return :red
    elseif a.status == :burnt
        return :darkred
    else
        return :green
    end
end



function run_forest_fire_model_old!()
    Random.seed!(2)
    forest = forest_fire()
    mdata = [burnt_percentage]
    df = init_model_dataframe(forest,mdata) 
    anim = @animate for i in 0:50
        if i > 0 
            step!(forest, tree_step!, 1)
        end
        collect_model_data!(df,forest,mdata,i)
        p1 = plotabm(forest; ac = treecolor, ms = 5, msw = 0)
        title!(p1,"step $(i)")
    end
    animated_gif = gif(anim, "forest.gif", fps=2)
    return (animated_gif, df)
end



function run_forest_fire_model!(file;frames=60,spf=1)
    Random.seed!(2)
    forest = forest_fire()
    mdata = [burnt_percentage]
    df = init_model_dataframe(forest, mdata)
    # Create 'Step N' as the Observable title
    s = Observable(0) # counter of current step
    t = lift(x -> "step = " * string(x), s)
    axiskwargs = (title = t, titlealign = :left) #title and position
    # create figure of the first frame to feed it into record
    fig, abmstepper = abm_plot(
        forest;
        ac = treecolor,
        axiskwargs = axiskwargs,
        ms = 5,
        msw = 0
    )
    # record the animation Makie style
    record(fig, file) do io
        for j in 1:frames-1
            recordframe!(io)
            # MUST USE THE SAME ABMSTEPPER! otherwise frame won't update
            step!(abmstepper, forest, tree_step!, dummystep, spf)
            collect_model_data!(df,forest,mdata,j)
            s[] += spf # update the observable step
            #s[] = s[] # Not sure why?
        end
        recordframe!(io) # last frame
    end
    isfile(file) || error("file not created")
    return (file,df)
end

#_,df = run_forest_fire_model!("forest_new.mp4")
end