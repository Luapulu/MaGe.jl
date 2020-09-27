function parse_meta(stream::IO)
    eventnum = Parsers.parse(Int64, readuntil(stream, ' '))
    hitcount = Parsers.parse(Int64, readuntil(stream, ' '))
    primarycount = Parsers.parse(Int64, readuntil(stream, '\n'))
    return eventnum, hitcount, primarycount
end

function parse_hit(stream::IO)
    x = Parsers.parse(Float64, readuntil(stream, ' '))
    y = Parsers.parse(Float64, readuntil(stream, ' '))
    z = Parsers.parse(Float64, readuntil(stream, ' '))
    E = Parsers.parse(Float64, readuntil(stream, ' '))
    t = Parsers.parse(Float64, readuntil(stream, ' '))
    particleid = Parsers.parse(Int64, readuntil(stream, ' '))
    trackid = Parsers.parse(Int64, readuntil(stream, ' '))
    trackparentid = Parsers.parse(Int64, readuntil(stream, ' '))

    skip(stream, 9)

    return Hit(x, y, z, E, t, particleid, trackid, trackparentid)
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
end

Base.IteratorSize(::Type{RootHitReader}) = Base.SizeUnknown()

Base.IteratorEltype(::Type{RootHitReader}) = Base.HasEltype()
Base.eltype(::Type{RootHitReader}) = Event{RootHitIter}

function Base.iterate(reader::RootHitReader, state = nothing)
    eof(reader.stream) && return (close(reader); nothing)
    return read(reader), nothing
end

function Base.read(reader::RootHitReader, T=Event{RootHitIter})
    enum, hitcnt, primcnt = parse_meta(reader.stream)
    return convert(T, Event(enum, hitcnt, primcnt, RootHitIter(hitcnt, reader.stream)))
end

function Base.close(reader::RootHitReader)
    reader.ownstream && close(reader.stream)
end

loadstreaming(stream::IO) = RootHitReader(stream, false)
loadstreaming(f::Function, stream::IO) = f(loadstreaming(stream))

loadstreaming(path::AbstractString) = RootHitReader(open(path), true)
loadstreaming(f::Function, path::AbstractString) = f(loadstreaming(path))

is_root_hit_file(path::AbstractString) = occursin(r"root.hits$", path)

function load(f::AbstractString; T=Event{Vector{Hit}})
    is_root_hit_file(f) || error("cannot read events from $f")
    loadstreaming(f) do stream
        return collect(T, stream)
    end
end
