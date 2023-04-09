module Miner

using GLMakie
using CoherentNoise
# using LinearAlgebra
# using GeometryTypes
using GeometryBasics
# using ImageEdgeDetection
# using ImageTransformations
using Colors
using FixedPointNumbers
using FileIO
using WAV
using Base.Threads

GLMakie.activate!(float=true)

include("player_controller.jl")
include("sqlite_manager.jl")
include("world_manager.jl")
include("block_manager.jl")
include("utilities.jl")

export start_game, BlockType

function distance(a::Point3f0, b::Point3f0)
    dist = sqrt((b[1] - a[1])^2 + (b[2] - a[2])^2 + (b[3] - a[3])^2)
    return dist
end

function adjacent_blocks(a::Point3f0)
    neighbors = map(x -> a .+ x, [Point3f0(1, 0, 0), Point3f0(-1, 0, 0), Point3f0(0, 1, 0), Point3f0(0, -1, 0), Point3f0(0, 0, 1), Point3f0(0, 0, -1)])
    return neighbors
end

function distance(a::Point3f0, b::Vector{Point3f0})
    dist = map(x -> distance(a, x), b)
    ord = sortperm(dist;)
    return b[ord]
end

scatter_cases = Dict(
    10 => Vec4f(0 / 16, 12 / 16, 1 / 16, 13 / 16),
    11 => Vec4f(1 / 16, 12 / 16, 2 / 16, 13 / 16),
    12 => Vec4f(2 / 16, 12 / 16, 3 / 16, 13 / 16),
    13 => Vec4f(3 / 16, 12 / 16, 4 / 16, 13 / 16),
    14 => Vec4f(4 / 16, 12 / 16, 5 / 16, 13 / 16),
    15 => Vec4f(5 / 16, 12 / 16, 6 / 16, 13 / 16),
    16 => Vec4f(6 / 16, 12 / 16, 7 / 16, 13 / 16),
)

function start_game()
    @info "Starting Game!"

    # @info "Setting up Database!"
    # db = setup_database("database/world.db")

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

    chnl = Channel{String}(32)
    songs = filter(x -> endswith(x, ".wav"), readdir("assets"))
    song_name = Observable(1)

    song_text = Observable("This will be added to queue: $(songs[song_name[]])")
    text!(subscene, Point(10, 50), text=song_text)

    # current_song = Observable("Now Playing:")
    # text!(subscene, Point(10, 70), text=current_song)

    music_on = Observable(true)

    function music_player()
        while music_on[]
            # @info music_on[] isready(chnl)
            if (isready(chnl))
                @info "Music Player: Song start!"
                file = take!(chnl)
                @info "Now Playing $file"
                y, fs = wavread(file)
                wavplay(y, fs)
                # current_song[] = "Now Playing: $file"
                # notify(current_song)
                @info "Music Player: Song ended!"
            end
            sleep(5)
        end
        @info "Music Player: Stopped!"
    end
    Threads.@spawn music_player()

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
            notify(i)
            scatter!(scene,
                i,
                rotations=[repeat([up], Int(length(i[]) / 2)); repeat([up * qrotation(Vec3f(0, 1, 0), 0.5pi)], Int(length(i[]) / 2))],
                markerspace=:data,
                marker=Rect,
                markersize=1.0,
                uv_offset_width=repeat([uv], length(i[])),
                image=tex,
                fxaa=false,
                transparency=true)
        else
            a = meshscatter!(scene, i; markersize=1, marker=marker, color=tex)
        end
    end



    # for block adding and breaking
    on(events(scene).mousebutton) do button
        if (button.button == Makie.Mouse.left && button.action == Makie.Mouse.press)
            p, idx = pick(scene)

            locMouse[] = string("Mouse click on object at: ", round.(Int, p.positions[][idx]))
            notify(locMouse)

            if (p === nothing)
                return
            end

            loc = p.positions[][idx]
            if (block_state(Int(loc[1]), Int(loc[2]), Int(loc[3])) == BlockType(17))
                put!(chnl, joinpath("assets", songs[song_name[]]))
                @info "Music Player Queue : $(songs[song_name[]]) added and now has $(length(chnl.data)) songs in queue!"
                return
            end


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
            notify(locMouse)

            # music box


            loc = p.positions[][idx]
            if (block_state(Int(loc[1]), Int(loc[2]), Int(loc[3])) == BlockType(17))
                chnl.data = Vector{String}([])
                @info "Music Player Queue : No songs in queue!"
                # schedule(music, ErrorException("stop"), error=true)
                return
            end
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
        notify(framerate)

        camloc[] = string("Current Loc:", round.(Int, cameracontrols(scene).eyeposition[]))
        notify(camloc)

        if (button.key == Makie.Keyboard._1 && button.action == Makie.Keyboard.press)
            if (Int(currBlock[]) > 2)
                currBlock[] = BlockType(Int(currBlock[]) - 1)
                txt[] = string(currBlock[])
                notify(currBlock)
                notify(txt)
            end
        elseif (button.key == Makie.Keyboard._2 && button.action == Makie.Keyboard.press)
            if (Int(currBlock[]) < 8)
                currBlock[] = BlockType(Int(currBlock[]) + 1)
                txt[] = string(currBlock[])
                notify(currBlock)
                notify(txt)
            end
        elseif (button.key == Makie.Keyboard._4 && button.action == Makie.Keyboard.press)
            if (song_name[] > 1)
                song_name[] = song_name[] - 1
                notify(song_name)

                song_text[] = "This will be added to queue: $(songs[song_name[]])"
                notify(song_text)
            end
        elseif (button.key == Makie.Keyboard._5 && button.action == Makie.Keyboard.press)
            if (song_name[] < length(songs))
                song_name[] = song_name[] + 1
                notify(song_name)

                song_text[] = "This will be added to queue: $(songs[song_name[]])"
                notify(song_text)
            end
        end


        # currTime = time()
        # diff = currTime - lastTime
        # if (diff > 3)
            # imga = Gray{N0f8}.(GLMakie.Makie.colorbuffer(GLMakie.Makie.getscreen(scene)))
            # img_edges = detect_edges(imga, Canny(spatial_scale=10, high=Percentile(80), low=Percentile(20)))
            # img1 = imresize(img_edges, 150,200)
            # img[] =  rotr90(img1)
            # # save("img1.png", img1)
            # notify(img)
        #     lastTime = currTime
        # end

        initial = c.eyeposition[]
        initial1 = c.lookat[]
        if (button.key == Makie.Keyboard.space && button.action == Makie.Keyboard.press)
            t = 0.03
            c.eyeposition[] = [initial[1], 3(t) - 5(t^2) + initial[2], initial[3]]
            @async while (c.eyeposition[] != initial)
                @info block_state(Int(initial[1]), Int(initial[2]), Int(initial[3]))
                if (block_state(Int(initial[1]), Int(initial[2]), Int(initial[3])) != BlockType(1))
                    c.eyeposition[] = [initial[1], initial[2] + 1, initial[3]]
                    break
                end
                c = cameracontrols(scene)
                c.eyeposition[] = [initial[1], 5(t) - 5(t^2) + initial[2], initial[3]]
                c.lookat[] = [initial1[1], 5(t) - 5(t^2) + initial1[2], initial1[3]]
                update_cam!(scene)
                sleep(0.03)
                t += 0.03
            end
        end
    end
    display(scene)
end

end # module Miner
