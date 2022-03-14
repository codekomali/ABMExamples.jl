# Copyright (c) 2022 Code Komali
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

module ForestFireExample

export run_forest_fire_model!

using Agents
using Random
using Plots

mutable struct Tree <: AbstractAgent
    id::Int
    pos::Dims{2}
    status::Symbol
end

function forest_fire(;
    density = 0.7,
    griddims = (100, 100)
    )
    space = GridSpace(griddims; periodic=false, metric= :euclidean)
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
    burntTrees = count(t->t.status == :burnt, allagents(m))
    totArea = length(positions(m))
    return burntTrees/totArea
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

function run_forest_fire_model!()
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

#run_forest_fire_model!()

#init_model_dataframe(forest,[burnt_percentage])
end  