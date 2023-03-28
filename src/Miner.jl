module Miner

using GLMakie
using CoherentNoise
using LinearAlgebra
using GeometryTypes
using GeometryBasics
using ProgressMeter 
GLMakie.activate!(;)

export start_game

function start_game()
    @info "Starting Game!"
    p = Progress(10)

    @info "Setting up database connection"
    sleep(200)
    next!(p)

    @info "Setting up scene"
    sleep(200)
    finish!(p)
end

end # module Miner
