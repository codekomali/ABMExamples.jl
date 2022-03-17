# Copyright (c) 2022 Code Komali
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

module FlockingExample

export run_flocking_example!

using Agents
using LinearAlgebra
using InteractiveDynamics
using CairoMakie
using Makie.GeometryBasics # without this UndefVarError: Point2f0

mutable struct Bird <: AbstractAgent
    id::Int
    pos::NTuple{2,Float64}
    vel::NTuple{2,Float64}
    speed::Float64
    cohere_factor::Float64
    separation::Float64
    separate_factor::Float64
    match_factor::Float64
    visual_distance::Float64
end

function random_angle(rng)
    rand_deg = rand(rng,0:360)
    rad = deg2rad(rand_deg)
    return (cos(rad), sin(rad))
end

function initialize_model(;
    n_birds = 100,
    speed = 1.0,
    cohere_factor = 0.25,
    separation = 4.0,
    separate_factor = 0.25,
    match_factor = 0.01,
    visual_distance = 5.0,
    extent = (100, 100),
    spacing = visual_distance / 1.5,
)
    space2d = ContinuousSpace(extent, spacing)
    model = ABM(Bird, space2d, scheduler = Schedulers.randomly)
    for _ in 1:n_birds
        # randomly assign the heading for each bird
        # the * 2 .-1 ensures that we are covering all 360deg
        # otherwise rand will only generate +ve numbers
        # which effectively locks us within 90*
        # vel = Tuple(rand(model.rng, 2) * 2 .- 1)
        vel = random_angle(model.rng)
        add_agent!(
            model,
            vel,
            speed,
            cohere_factor,
            separation,
            separate_factor,
            match_factor,
            visual_distance,
        )
    end
    return model
end

"""
    heading_to_new_pos(current_pos, new_pos)
The heading that agent should turn to go towards the new_pos
Return `heading`
"""
heading_to_new_pos(current_pos, new_pos) = new_pos .- current_pos
 
function agent_step!(bird, model)
    # Obtain the ids of neighbors within the bird's visual distance
    neighbor_ids = nearby_ids(bird, model, bird.visual_distance)
    N = 0
    match = separate = cohere = (0.0, 0.0)
    # Calculate behaviour properties based on neighbors
    for id in neighbor_ids
        N += 1
        neighbor = model[id]
        # the heading that the bird has to turn, if it were to go towards the neighbor bird
        heading = heading_to_new_pos(bird.pos, neighbor.pos)
        # `cohere` computes the average position of neighboring birds
        cohere = cohere .+ heading
        if edistance(bird.pos, neighbor.pos, model) < bird.separation
            # `separate` repels the bird away from neighboring birds
            # ' - heading' indicates head in the opposite direction of the neighboring bird
            separate = separate .- heading
        end
        # `match` computes the average trajectory of neighboring birds
        match = match .+ model[id].vel
    end
    N = max(N, 1)
    # Normalise results based on model input and neighbor count
    cohere = cohere ./ N .* bird.cohere_factor
    separate = separate ./ N .* bird.separate_factor
    match = match ./ N .* bird.match_factor
    # Compute velocity (heading) based on rules defined above
    bird.vel = (bird.vel .+ cohere .+ separate .+ match) ./ 2
    bird.vel = bird.vel ./ norm(bird.vel)
    # Move bird according to new velocity and speed
    move_agent!(bird, model, bird.speed)
end

const bird_polygon = Polygon(Point2f0[(-0.5, -0.5), (1, 0), (-0.5, 0.5)])

function bird_marker(b::Bird)
    φ = atan(b.vel[2], b.vel[1]) #+ π/2 + π
    scale(rotate2D(bird_polygon, φ), 2)
end

function run_flocking_example!()
    model = initialize_model()
    # And let's also do a nice little video for it:
    abm_video(
        "flocking.mp4", model, agent_step!;
        am = bird_marker,
        framerate = 20, frames = 200,
        title = "Flocking"
    )
end
#run_flocking_example!()
end