module ABMExamples

include("SchellingsSegregation.jl")
include("ForestFire.jl")
include("HKOpinionDynamics.jl")
include("Flocking.jl")

import .SchellingExample: run_schelling_model!
import .ForestFireExample: run_forest_fire_model!
import .HKOpinionDynamicsExample: hk_model_run_and_plot!
import .FlockingExample: run_flocking_example!

export run_schelling_model!
export run_forest_fire_model!
export hk_model_run_and_plot!
export run_flocking_example!

end
