using ABMExamples
using Test
using Statistics: mean

@testset "ABMExamples.jl" begin
    @testset "SchellingsSegregation.jl" begin
        schelling_data, schelling_filename = run_schelling_model!(20,"schelling")
        @show mean(schelling_data.sum_mood)
        @test mean(schelling_data.sum_mood) == 274.0
    end
    @testset "ForestFire.jl" begin
        _,ff_data = run_forest_fire_model!()
        rounded = round(mean(ff_data.burnt_percentage), digits=2)
        @test rounded == 0.3
    end
    @testset "HKOpinionDynamics.jl" begin
        all_data = hk_model_run_and_plot!()
        # we are testing only ϵ = 0.3, which is the last in the list
        data_epsilon_03 = all_data[end]
        rounded = round(
            mean(data_epsilon_03.new_opinion),
            digits=2
        )
        @test rounded == 0.54
    end
end
