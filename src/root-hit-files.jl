function parse_meta(stream::IOStream)
    line = IOBuffer(readuntil(stream, '\n'))
    return (
        Parsers.parse(Int64, line),
        Parsers.parse(Int64, line),
        Parsers.parse(Int64, line)
    )
end

function parse_hit(stream::IOStream)
    line = IOBuffer(readuntil(stream, UInt8('p')))
    skip(stream, 8)
    return Hit(
        Parsers.parse(Float64, line),
        Parsers.parse(Float64, line),
        Parsers.parse(Float64, line),
        Parsers.parse(Float64, line),
        Parsers.parse(Float64, line),
        Parsers.parse(Int64, line),
        Parsers.parse(Int64, line),
        Parsers.parse(Int64, line)
    )
end

struct RootHitIter <: AbstractHitIter
    hitcount::Integer
    stream::IO
end

Base.length(itr::RootHitIter) = itr.hitcount
Base.eltype(::Type{RootHitIter}) = Hit

function Base.iterate(itr::RootHitIter, i = 0)
    i == itr.hitcount && return nothing
    return parse_hit(itr.stream), i + 1
end

struct RootHitReader
    stream::IO
    ownstream::Bool
    lock::ReentrantLock
end

function RootHitReader(stream::IOStream, ownstream::Bool)
    RootHitReader(stream, ownstream, stream.lock)
end

function RootHitReader(stream::IO, ownstream::Bool)
    RootHitReader(stream, ownstream, ReentrantLock())
end

Base.IteratorSize(::Type{RootHitReader}) = Base.SizeUnknown()

Base.IteratorEltype(::Type{RootHitReader}) = Base.HasEltype()
Base.eltype(::Type{RootHitReader}) = Event{RootHitIter}

function Base.iterate(reader::RootHitReader, state = nothing)
    eof(reader) && return (close(reader); nothing)
    return read(reader, Event{Vector{Hit}}), nothing
end

function Base.read(reader::RootHitReader, T=Event{Vector{Hit}})
    lock(reader.lock) do
        enum, hitcnt, primcnt = parse_meta(reader.stream)
        return convert(T, Event(enum, hitcnt, primcnt, RootHitIter(hitcnt, reader.stream)))
    end
end

function Base.eof(reader::RootHitReader)
    lock(reader.lock) do
        eof(reader.stream)
    end
end

function Base.close(reader::RootHitReader)
    if reader.ownstream
        lock(reader.lock) do
            close(reader.stream)
        end
    end
end

loadstreaming(stream::IO) = RootHitReader(stream, false)
loadstreaming(f::Function, stream::IO) = f(loadstreaming(stream))

loadstreaming(path::AbstractString) = RootHitReader(open(path, lock=false), true)
function loadstreaming(f::Function, path::AbstractString)
    reader = loadstreaming(path)
    try
        return f(reader)
    finally
        close(reader)
    end
end

is_root_hit_file(path::AbstractString) = occursin(r"root.hits$", path)

function load(stream::IO; T=Event{Vector{Hit}})
    loadstreaming(stream) do stream
        return collect(T, stream)
    end
end

function load(path::AbstractString; T=Event{Vector{Hit}})
    is_root_hit_file(path) || error("cannot read events from $f")
    open(path, lock=false) do f
        return load(f; T=T)
    end
end
