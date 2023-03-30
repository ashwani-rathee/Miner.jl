
export chunk_index, chunk_center, central_chunk, chunk_range, block_state, generate_chunk

# perlin noise
sampler = perlin_2d(;seed=1)

"""
    chunk_index(x::Int, z::Int)

Returns chunk Indexes based on their central value (x,z) in a world where 
chunk size is 64*64 in x and z direction

"""
function chunk_index(x::Int, z::Int)
    return ( floor(Int, x/48), floor(Int, z/48))
end

"""
    chunk_center(chunkindexX::Int, chunkindexZ::Int)

Returns chunk center based on central point of those chunks
"""
function chunk_center(chunkindexX::Int, chunkindexZ::Int)
    return (chunkindexX*48, chunkindexZ*48)
end


"""
    central_chunk(x::Int, z::Int)

Return the central_chunk location based on x, z
"""
function central_chunk(x::Int, z::Int)
    return chunk_center(floor(Int, (x+32)/64), floor(Int, (z+32)/64))
end

"""
    chunk_range(chunkindexX::Int, chunkindexZ::Int)

Return range of x and z that chunks has
"""
function chunk_range(chunkindexX::Int, chunkindexZ::Int)
    return ((chunkindexX-32):1:(chunkindexX+31),  (chunkindexZ-32):1:(chunkindexZ+31))
end

"""
    block_state(x::Int, y::Int, z::Int)

Return any x,y,z this function tells the block state that locations should be in
"""
function block_state(x::Int, y::Int, z::Int)
    surfaceY = 5;
    rands = trunc(Int, 10*sample(sampler, x/10, z/10));
    surfaceY = surfaceY + rands;
    # return (y<surfaceY) ? (:gray, 0.9) : (:gray, 0);
    seaLevel = 4
    if (y<surfaceY)
        return (y<3) ? BlockType(1) : BlockType(3)
    elseif (y< seaLevel)
        return BlockType(2)
    else
        return BlockType(0)
    end
end

function block_state1(x::Int, y::Int, z::Int)
    surfaceY = 5;
    rands = trunc(Int, 10*sample(sampler, x/10, z/10));
    surfaceY = surfaceY + rands;
    # return (y<surfaceY) ? (:gray, 0.9) : (:gray, 0);
    seaLevel = 4
    if (y<surfaceY)
        return (y<3) ? (:gray, 1.0) : (:green, 1.0)
    elseif (y< seaLevel)
        return (:blue, 0.2)
    else
        return (:grey,0)
    end
end

@enum BlockType begin
    air = 0
    stone = 1
    water = 2
    grass = 3
    dirt = 4
    wood = 5
    leaves = 6
end


"""
    generate_chunk(chunkindexX::Int, chunkindexZ::Int)

Process and adds chunks blocks to database for later use.
"""
function generate_chunk(db, chunkindexX::Int, chunkindexZ::Int)
    xrange, zrange = chunk_range(chunkindexX, chunkindexZ)
    @info xrange, zrange
    yrange = 0:1:20

    write_query = DBInterface.prepare(db, "INSERT INTO chunks (sno, chunkX, chunkZ, x, y, z, blocktype) VALUES (?,?,?,?,?,?,?)") 
    snos = Vector{String}([])
    xs = Vector{Int}([])
    ys = Vector{Int}([])
    zs = Vector{Int}([])
    bls = Vector{Int}([])
    for x in xrange, y in yrange, z in zrange
        push!(snos, join([x,y,z], '-'))
        push!(xs, x)
        push!(ys, y)
        push!(zs, z)
        push!(bls, Int(block_state(x, y, z)))
    end
    @info length(snos)
    cXs = [chunkindexX for i in 1:length(snos)]
    cZs = [chunkindexZ for i in 1:length(snos)]
    table_data = (sno=snos, chunkX=cXs, chunkZ=cZs, x=xs, y=ys, z=zs, blocktype=bls)
    DBInterface.executemany(write_query, table_data) 
end


function surface_height(x::Int, z::Int)
    surfaceY = 5;
    rands = trunc(Int, 10*sample(sampler, x/10, z/10));
    surfaceY = surfaceY + rands;
    return surfaceY
end