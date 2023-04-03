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
include("BlockManager.jl")

export start_game, BlockType

function start_game()
    @info "Starting Game!"

    @info "Setting up Database!"
    db = setup_database("database/world.db")

    scene = Scene(;backgroundcolor=:grey)
    pc = PlayerController(scene)

    c = cameracontrols(scene)
    c.eyeposition[] = (0,surface_height(0,0)+3,0)
    c.lookat[] = Vec3f(-1,surface_height(0,0)+1,-1)
    c.upvector[] = (1, 1, 1)
    update_cam!(scene)

    subscene = Scene(scene); 
    campixel!(subscene)
    txt = Observable("Test framerate: 10 fps")
    currBlock = Observable(BlockType(1))
    txt = Observable("stone")
    text!(subscene, Point(10,10), text = txt)


    # mark = GLMakie.Rect3f(Vec3f(0), Vec3f(1));
    # 
    # colS = Observable([block_state1(trunc(Int, i.data[1]),trunc(Int, i.data[2]), trunc(Int, i.data[3]) ) for i in positions[]])
    # meshscatter!(scene, positions, marker=mark, markersize=1f0, color=colS, interpolate=false)
    # positions = Observable(vec([GLMakie.Point3f0(x, y, z) for x in -16:1:16, y in -16:1:32, z in -16:1:16]))
    positionAir = Observable(Vector{GLMakie.Point3f0}([]))
    positionStones = Observable(Vector{GLMakie.Point3f0}([]))
    positionWater = Observable(Vector{GLMakie.Point3f0}([]))
    positionGrass =  Observable(Vector{GLMakie.Point3f0}([]))
    positionDirt =  Observable(Vector{GLMakie.Point3f0}([]))
    positionWood =  Observable(Vector{GLMakie.Point3f0}([]))
    positionLeaves =  Observable(Vector{GLMakie.Point3f0}([]))
    positionBedRock =  Observable(Vector{GLMakie.Point3f0}([]))
    positionCloud =  Observable(Vector{GLMakie.Point3f0}([]))
    for x in -32:1:32, y in -16:1:32, z in -32:1:32
        # @info "loc:" x y z
        if (block_state(x, y, z) == BlockType(0))
            push!(positionAir[], GLMakie.Point3f0(x, y, z))
        elseif (block_state(x, y, z) == BlockType(1))
            push!(positionStones[], GLMakie.Point3f0(x, y, z))
        elseif (block_state(x, y, z) == BlockType(2))
            push!(positionWater[], GLMakie.Point3f0(x, y, z))
        elseif (block_state(x, y, z) == BlockType(3))
            push!(positionGrass[], GLMakie.Point3f0(x, y, z))
        elseif (block_state(x, y, z) == BlockType(4))
            push!(positionDirt[], GLMakie.Point3f0(x, y, z))
        elseif (block_state(x, y, z) == BlockType(5))
            push!(positionWood[], GLMakie.Point3f0(x, y, z))
        elseif (block_state(x, y, z) == BlockType(6))
            push!(positionLeaves[], GLMakie.Point3f0(x, y, z))
        elseif (block_state(x, y, z) == BlockType(7))
            push!(positionBedRock[], GLMakie.Point3f0(x, y, z))
        elseif (block_state(x, y, z) == BlockType(8))
            push!(positionCloud[], GLMakie.Point3f0(x, y, z))
        end
    end
    if(length(positionAir[])>0) meshscatter!(scene, positionAir; markersize=1, marker=return_mesh(BlockType(0)), color=(:grey, 0), transparency = true) end
    if(length(positionStones[])>0) meshscatter!(scene, positionStones; markersize=1, marker=return_mesh(BlockType(1)), color=tex) end
    if(length(positionWater[])>0) meshscatter!(scene, positionWater; markersize=1, marker=return_mesh(BlockType(2)), color=tex) end
    if(length(positionGrass[])>0) meshscatter!(scene, positionGrass; markersize=1, marker=return_mesh(BlockType(3)), color=tex) end
    if(length(positionDirt[])>0) meshscatter!(scene, positionDirt; markersize=1, marker=return_mesh(BlockType(4)), color=tex) end
    if(length(positionWood[])>0) meshscatter!(scene, positionWood; markersize=1, marker=return_mesh(BlockType(5)), color=tex) end
    if(length(positionLeaves[])>0) meshscatter!(scene, positionLeaves; markersize=1, marker=return_mesh(BlockType(6)), color=tex) end
    if(length(positionBedRock[])>0) meshscatter!(scene, positionBedRock; markersize=1, marker=return_mesh(BlockType(7)), color=tex) end
    if(length(positionCloud[])>0) meshscatter!(scene, positionCloud; markersize=1, marker=return_mesh(BlockType(0)), color=(:white, 1)) end

    
    # for block adding and breaking
    on(events(scene).mousebutton) do button
        # if (button.button == Makie.Mouse.left && button.action == Makie.Mouse.press)
        #     p, idx = pick(scene)
        #     if( p === nothing)
        #         return
        #     end
        #     a =  positions[]
        #     b = a[idx]
        #     push!(positions[],Point3f0([b[1],b[2]+1,b[3]]))
        #     push!(colS[], (:gray, 0.5))
        #     # vec(rand(RGBf, 1))[1]
        #     notify(positions)
        #     notify(colS)
        # elseif (button.button == Makie.Mouse.right && button.action == Makie.Mouse.press)
        #     p, idx = pick(scene)
        #     @info p
        #     # deleteat!(positions[], idx)
        #     # notify(positions)
        # end
    end

    on(events(scene).keyboardbutton) do button
        if (button.key == Makie.Keyboard._1 && button.action == Makie.Keyboard.press)
            if(Int(currBlock[]) > 0)
                currBlock[] = BlockType(Int(currBlock[]) - 1)
                txt[] = string(currBlock[])
                notify(currBlock)
                notify(txt)
            end
        elseif (button.key == Makie.Keyboard._2 && button.action == Makie.Keyboard.press)
            if(Int(currBlock[]) < 8)
                currBlock[] = BlockType(Int(currBlock[]) + 1)
                txt[] = string(currBlock[])
                notify(currBlock)
                notify(txt)
            end
        end
    end
    scene
end

end # module Miner
