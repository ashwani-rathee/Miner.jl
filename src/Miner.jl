module Miner

using GLMakie
using CoherentNoise
# using LinearAlgebra
# using GeometryTypes
# using GeometryBasics
GLMakie.activate!(;)

include("SqliteManager.jl")
include("WorldManager.jl")

export start_game

function start_game()
    @info "Starting Game!"

    @info "Setting up Database!"
    db = setup_database("database/world.db")

end

end # module Miner
