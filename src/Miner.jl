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
    m = normal_mesh(Rect3f(Vec3f(-0.5) .+ o, sizexyz))
    m = GeometryBasics.Mesh(meta(coordinates(m);
        uv = uvs, normals = normals(m)), faces(m))
end



function start_game()
    @info "Starting Game!"

    @info "Setting up Database!"
    db = setup_database("database/world.db")

    scene = Scene(;backgroundcolor=:grey)
    pc = PlayerController(scene)

    c = cameracontrols(scene)
    c.eyeposition[] = (0,surface_height(0,0)+1,0)
    c.lookat[] = Vec3f(-1,surface_height(0,0)+1,-1)
    c.upvector[] = (1, 1, 1)
    update_cam!(scene)

    mark = GLMakie.Rect3f(Vec3f(0), Vec3f(1));
    positions = Observable(vec([GLMakie.Point3f0(x, y, z) for x in -16:1:16, y in -16:1:32, z in -16:1:16]))
    colS = Observable([block_state1(trunc(Int, i.data[1]),trunc(Int, i.data[2]), trunc(Int, i.data[3]) ) for i in positions[]])
    meshscatter!(scene, positions, marker=mark, markersize=1f0, color=colS, interpolate=false)

    # for block adding and breaking
    on(events(scene).mousebutton) do button
        if (button.button == Makie.Mouse.left && button.action == Makie.Mouse.press)
            p, idx = pick(scene)
            if( p === nothing)
                return
            end
            a =  positions[]
            b = a[idx]
            push!(positions[],Point3f0([b[1],b[2]+1,b[3]]))
            push!(colS[], (:gray, 0.5))
            # vec(rand(RGBf, 1))[1]
            notify(positions)
            notify(colS)
        elseif (button.button == Makie.Mouse.right && button.action == Makie.Mouse.press)
            p, idx = pick(scene)
            deleteat!(positions[], idx)
            deleteat!(colS[], idx)
            notify(positions)
            notify(colS)
        end
    end

    scene
end

end # module Miner
