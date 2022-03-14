module ABMExamples

include("SchellingsSegregation.jl")
include("ForestFire.jl")

import .SchellingExample: run_schelling_model!
import .ForestFireExample: run_forest_fire_model!

export run_schelling_model!
export run_forest_fire_model!

end
