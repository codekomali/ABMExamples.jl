using ABMExamples
using Test
using Statistics: mean

@testset "ABMExamples.jl" begin
    schelling_data, schelling_filename = run_model!(20,"schelling")
    @show mean(schelling_data.sum_mood)
    @test mean(schelling_data.sum_mood) == 274.0
end
