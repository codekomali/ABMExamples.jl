module PredatorPreyExample

export run_predatorprey_model!

using Agents
using Random
using InteractiveDynamics
using CairoMakie

mutable struct SheepWolf <: AbstractAgent
    id::Int
    pos::Dims{2}
    type::Symbol
    energy::Float64
    reproduction_prob::Float64
    Δenergy::Float64
end

Sheep(id, pos, energy, reprob, Δe) = SheepWolf(id, pos, :sheep, energy, reprob, Δe)
Wolf(id, pos, energy, reprob, Δe) = SheepWolf(id, pos, :wolf, energy, reprob, Δe)

function initialize_sheep!(model, n_sheep; start_id=0, Δenergy_sheep=4, sheep_reproduce=0.04)
    id = start_id
    for _ in 1:n_sheep
        id += 1
        energy = rand(model.rng, 1:(Δenergy_sheep*2)) - 1
        sheep = Sheep(id, (0, 0), energy, sheep_reproduce, Δenergy_sheep)
        add_agent!(sheep, model)
    end
end

function initialize_wolves!(model, n_wolves; start_id=0, Δenergy_wolf=20, wolf_reproduce=0.05)
    id = start_id
    for _ in 1:n_wolves
        id += 1
        energy = rand(model.rng, 1:(Δenergy_wolf*2)) - 1
        wolf = Wolf(id, (0, 0), energy, wolf_reproduce, Δenergy_wolf)
        add_agent!(wolf, model)
    end
end

function initialize_grass!(model; regrowth_time=30)
    for p in positions(model) # random grass initial growth
        fully_grown = rand(model.rng, Bool)
        countdown = fully_grown ? regrowth_time : rand(model.rng, 1:regrowth_time) - 1
        model.countdown[p...] = countdown
        model.fully_grown[p...] = fully_grown
    end
end

function initialize_model(;
    n_sheep=100,
    n_wolves=50,
    dims=(20, 20),
    regrowth_time=30,
    Δenergy_sheep=4,
    Δenergy_wolf=20,
    sheep_reproduce=0.04,
    wolf_reproduce=0.05,
    seed=23182
)

    rng = MersenneTwister(seed)
    space = GridSpace(dims, periodic=false)
    # Model properties contain the grass as two arrays: whether it is fully grown
    # and the time to regrow. Also have static parameter `regrowth_time`.
    # Notice how the properties are a `NamedTuple` to ensure type stability.
    properties = (
        fully_grown=falses(dims),
        countdown=zeros(Int, dims),
        regrowth_time=regrowth_time,
    )
    model = ABM(SheepWolf, space; properties, rng, scheduler=Schedulers.randomly)
    initialize_sheep!(model, n_sheep;
        Δenergy_sheep=Δenergy_sheep,
        sheep_reproduce=sheep_reproduce
    )
    initialize_wolves!(model, n_wolves;
        start_id=n_sheep,
        Δenergy_wolf=Δenergy_wolf,
        wolf_reproduce=wolf_reproduce
    )
    initialize_grass!(model; regrowth_time=regrowth_time)
    return model
end

function sheepwolf_step!(agent::SheepWolf, model)
    if agent.type == :sheep
        sheep_step!(agent, model)
    else # then `agent.type == :wolf`
        wolf_step!(agent, model)
    end
end

function sheep_step!(sheep, model)
    walk!(sheep, rand, model)
    sheep.energy -= 1
    sheep_eat!(sheep, model)
    if sheep.energy < 0
        kill_agent!(sheep, model)
        return
    end
    if rand(model.rng) <= sheep.reproduction_prob
        reproduce!(sheep, model)
    end
end

function wolf_step!(wolf, model)
    wolf.energy -= 1
    agents = collect(agents_in_position(wolf.pos, model))
    dinner = filter!(x -> x.type == :sheep, agents)
    if isempty(dinner)
        walk!(wolf, rand, model)
    else
        walk!(wolf, rand, model)
    end
    wolf_eat!(wolf, dinner, model)
    if wolf.energy < 0
        kill_agent!(wolf, model)
        return
    end
    if rand(model.rng) <= wolf.reproduction_prob
        reproduce!(wolf, model)
    end
end

function sheep_eat!(sheep, model)
    if model.fully_grown[sheep.pos...]
        sheep.energy += sheep.Δenergy
        model.fully_grown[sheep.pos...] = false
    end
end

function wolf_eat!(wolf, sheep, model)
    if !isempty(sheep)
        dinner = rand(model.rng, sheep)
        kill_agent!(dinner, model)
        wolf.energy += wolf.Δenergy
    end
end

function reproduce!(agent, model)
    agent.energy /= 2
    id = nextid(model)
    offspring = SheepWolf(
        id,
        agent.pos,
        agent.type,
        agent.energy,
        agent.reproduction_prob,
        agent.Δenergy,
    )
    add_agent_pos!(offspring, model)
    return
end

function grass_step!(model)
    @inbounds for p in positions(model) # we don't have to enable bound checking
        if !(model.fully_grown[p...])
            if model.countdown[p...] ≤ 0
                model.fully_grown[p...] = true
                model.countdown[p...] = model.regrowth_time
            else
                model.countdown[p...] -= 1
            end
        end
    end
end


offset(a) = a.type == :sheep ? (-0.7, -0.5) : (-0.3, -0.5)
ashape(a) = a.type == :sheep ? :circle : :utriangle
acolor(a) = a.type == :sheep ? :white : :black
grasscolor(model) = model.countdown ./ model.regrowth_time
heatkwargs = (colormap = [:brown, :green], colorrange = (0, 1))
sheep(a) = a.type == :sheep
wolves(a) = a.type == :wolf
count_grass(model) = count(model.fully_grown)

adata = [(sheep, count), (wolves, count)]
mdata = [count_grass]
#adf, mdf = run!(model, sheepwolf_step!, grass_step!, n; adata, mdata)

function run_predatorprey_model!(;file="sheepwolf.mp4",frames=500,spf=1)
    model = initialize_model(
    n_wolves = 20,
    dims = (25, 25),
    Δenergy_sheep = 5,
    sheep_reproduce = 0.2,
    wolf_reproduce = 0.08,
    seed = 7758
    )
    adf = init_agent_dataframe(model, adata)
    mdf = init_model_dataframe(model, mdata)
    # Create 'Step N' as the Observable title
    s = Observable(0) # counter of current step
    t = lift(x -> "step = " * string(x), s)
    axiskwargs = (title = t, titlealign = :left) #title and position
    fig, abmstepper = abm_plot(
        model;     
        ac = acolor,
        as = 15,
        am = ashape,
        offset = offset,
        heatarray = grasscolor,
        heatkwargs = heatkwargs,
        axiskwargs = axiskwargs
    )
    record(fig, file; framerate = 8) do io
        for j in 1:frames-1
            recordframe!(io)
            # MUST USE THE SAME ABMSTEPPER! otherwise frame won't update
            step!(abmstepper, model, sheepwolf_step!, grass_step!, spf)
            collect_model_data!(mdf,model,mdata,j)
            collect_agent_data!(adf,model,adata,j)
            s[] += spf
        end
        recordframe!(io) # last frame
    end
    isfile(file) || error("file not created")
    return (file, adf, mdf)
end

function plot_population_timeseries(adf, mdf; figfile="predatorprey.png")
    figure = Figure(resolution = (600, 400))
    ax = figure[1, 1] = Axis(figure; xlabel = "Step", ylabel = "Population")
    sheepl = lines!(ax, adf.step, adf.count_sheep, color = :blue)
    wolfl = lines!(ax, adf.step, adf.count_wolves, color = :orange)
    grassl = lines!(ax, mdf.step, mdf.count_grass, color = :green)
    figure[1, 2] = Legend(figure, [sheepl, wolfl, grassl], ["Sheep", "Wolves", "Grass"])
    save(figfile,figure)
    isfile(figfile) || error("plot file not created")
    return figure
end

#_, adf, mdf = run_predatorprey_model!()
#plot_population_timeseries(adf, mdf)

end
