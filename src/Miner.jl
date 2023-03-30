module Miner

using GLMakie
using CoherentNoise
# using LinearAlgebra
# using GeometryTypes
using GeometryBasics
GLMakie.activate!(;)
using FileIO

include("PlayerController.jl")
include("SqliteManager.jl")
include("WorldManager.jl")

export start_game

function meshcube(o=Vec3f(0), sizexyz = Vec3f(1))
    uvs = map(v -> v ./ (3, 2), Vec2f[
    (0, 0), (0, 1), (1, 1), (1, 0),
    (1, 0), (1, 1), (2, 1), (2, 0),
    (2, 0), (2, 1), (3, 1), (3, 0),
    (0, 1), (0, 2), (1, 2), (1, 1),
    (1, 1), (1, 2), (2, 2), (2, 1),
    (2, 1), (2, 2), (3, 2), (3, 1),
    ])
    m = GLMakie.normal_mesh(Rect3f(Vec3f(-0.5) .+ o, sizexyz))
    m = GeometryBasics.Mesh(meta(coordinates(m);
        uv = uvs, normals = GLMakie.normals(m)), GLMakie.faces(m))
end


function start_game()
    @info "Starting Game!"

    @info "Setting up Database!"
    db = setup_database("database/world.db")

    scene = Scene()
    pc = PlayerController(scene)

    c = cameracontrols(scene)
    c.eyeposition[] = (0,surface_height(0,0)+2,0)
    c.lookat[] = Vec3f(0,0,0)
    c.upvector[] = (1, 1, 1)
    update_cam!(scene)

    # mark = GLMakie.Rect3f(Vec3f(0), Vec3f(1));
    mark = meshcube();
    positions = Observable(vec([GLMakie.Point3f0(x, y, z) for x in -16:1:16, y in 0:1:20, z in -16:1:16]))
    # colS = [block_state1(trunc(Int, i.data[1]),trunc(Int, i.data[2]), trunc(Int, i.data[3]) ) for i in positions[]]
    img = load("assets/acacia_bark_top.png")
    img = rand(RGBf, 2, 3)
    img = rand(RGBf, 2*6, 3*6)
    meshscatter!(scene, positions, marker=mark, markersize=1f0, color=img, interpolate=false)
    scatter!(scene, [Point3f(0), Point3f(1,0,0), Point3f(0,1,0), Point3f(0,0,1)], color = [:black, :red, :green, :blue])
    scene
end

end # module Miner
