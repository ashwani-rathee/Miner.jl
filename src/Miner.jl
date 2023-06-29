module Miner

using GLMakie
using CoherentNoise
using GeometryBasics
using Colors
using FixedPointNumbers
using FileIO

GLMakie.activate!(float=true)

include("player_controller.jl")
include("world_manager.jl")
include("block_manager.jl")

export start_game

function start_game()
    @info "Starting Game!"

    scene = Scene(; backgroundcolor=:grey)
    pc = PlayerController(scene)

    subscene = Scene(scene)
    campixel!(subscene)

    world_changelocs = []
    world_changeblocks = []

    c = cameracontrols(scene)
    c.eyeposition[] = (5, surface_height(0, 0) + 3, 5)
    c.lookat[] = Vec3f(6, surface_height(0, 0) + 3, 6)
    c.upvector[] = (1, 1, 1)
    update_cam!(scene)

    currBlock = Observable(BlockType(2))
    text!(subscene, Point(10, 10), text="Block In-Hand:")

    txt = Observable("stone")
    text!(subscene, Point(120, 10), text=txt)

    framerate = Observable("10 fps")
    text!(subscene, Point(170, 10), text=framerate)

    camloc = Observable("Current Loc: [0,0,0]")
    text!(subscene, Point(220, 10), text=camloc)

    locMouse = Observable("Mouse click on object at: [0,0,0]")
    text!(subscene, Point(10, 30), text=locMouse)

    positionsAll = [Observable(Vector{GLMakie.Point3f0}([])) for i in 1:17]
    for x in -32:1:32, y in -16:1:32, z in -32:1:32
        push!(positionsAll[Int(block_state(x, y, z))][], GLMakie.Point3f0(x, y, z))
    end

    for (idx, i) in enumerate(positionsAll)
        marker = return_mesh(BlockType(idx))
        if (idx == 1)
            a = meshscatter!(scene, i; markersize=1, marker=marker, color=(:grey, 0))
        elseif (idx == 9)
            a = meshscatter!(scene, i; markersize=1, marker=marker, color=(:white, 0.8))
        elseif (idx in collect(10:16))
            i[] = repeat(i[] .- Point3f0(-0.5, -0.5, -0.5), 2)
            uv = scatter_cases[idx]
            up = qrotation(Vec3f(0, 1, 0), 0.5pi)
        else
            a = meshscatter!(scene, i; markersize=1, marker=marker, color=tex)
        end
    end



    # for block adding and breaking
    on(events(scene).mousebutton) do button
        if (button.button == Makie.Mouse.left && button.action == Makie.Mouse.press)
            p, idx = pick(scene)
            if (p === nothing)
                return
            end

            locMouse[] = string("Mouse click on object at: ", round.(Int, p.positions[][idx]))
            loc = p.positions[][idx]

            a = cameracontrols(scene).eyeposition[]
            a = Point3f0(a[1], a[2], a[3])
            b = adjacent_blocks(p.positions[][idx])
            order = distance(a, b)

            buildable = nothing

            for i in order
                if (block_state(Int(i[1]), Int(i[2]), Int(i[3])) == BlockType(1) && i ∉ world_changelocs)
                    buildable = i
                    break
                end
            end

            a = currBlock[]
            if (buildable !== nothing)
                push!(positionsAll[Int(a)][], buildable)
                push!(world_changelocs, buildable)
                push!(world_changeblocks, a)
            end

            notify(positionsAll[Int(a)])
        elseif (button.button == Makie.Mouse.right && button.action == Makie.Mouse.press)
            p, idx = pick(scene)
            locMouse[] = string("Mouse click on object at: ", round.(Int, p.positions[][idx]))

            loc = p.positions[][idx]
            if (p.positions[][idx] in world_changelocs)
                idx1 = findfirst(x -> x == p.positions[][idx], world_changelocs)
                deleteat!(world_changelocs, idx1)
                deleteat!(world_changeblocks, idx1)
            end
            deleteat!(p.positions[], idx)
            notify(p.positions)
        end
    end

    lastTime = time()
    lastTime1 = time()
    on(events(scene).keyboardbutton) do button
        framerate1 = 1 / (time() - lastTime1)
        lastTime1 = time()
        framerate[] = string(round(Int, framerate1), " fps")

        camloc[] = string("Current Loc:", round.(Int, cameracontrols(scene).eyeposition[]))

        if (button.key == Makie.Keyboard._1 && button.action == Makie.Keyboard.press)
            if (Int(currBlock[]) > 2)
                currBlock[] = BlockType(Int(currBlock[]) - 1)
                txt[] = string(currBlock[])
            end
        elseif (button.key == Makie.Keyboard._2 && button.action == Makie.Keyboard.press)
            if (Int(currBlock[]) < 8)
                currBlock[] = BlockType(Int(currBlock[]) + 1)
                txt[] = string(currBlock[])
            end
        end
    end
    display(scene)
end

end # module Miner
