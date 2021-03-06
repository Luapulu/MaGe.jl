## AbstractHit ##

abstract type AbstractHit end

function Base.show(io::IO, h::H) where {H<:AbstractHit}
    x, y, z = location(h)
    print(io, H, "(", x, ", ", y, ", ", z, ", ")
    print(io, energy(h), ", ", time(h), ", ")
    print(io, particleid(h), ", ", trackid(h), ", ", trackparentid(h), ")")
end


## Hit ##

struct Hit <: AbstractHit
    x::Float64
    y::Float64
    z::Float64
    E::Float64
    t::Float64
    particleid::Int
    trackid::Int
    trackparentid::Int
end

location(h::Hit) = (h.x, h.y, h.z)
energy(h::Hit) = h.E
Base.time(h::Hit) = h.t
particleid(h::Hit) = h.particleid
trackid(h::Hit) = h.trackid
trackparentid(h::Hit) = h.trackparentid

## AbstractHitIter ##

abstract type AbstractHitIter end

Base.IteratorSize(::Type{<:AbstractHitIter}) = Base.HasLength()
Base.IteratorEltype(::Type{<:AbstractHitIter}) = Base.HasEltype()

## Abstract Event ##

abstract type AbstractEvent end

Base.IteratorSize(::Type{<:AbstractEvent}) = Base.HasLength()
Base.length(e::AbstractEvent) = hitcount(e)

Base.IteratorEltype(::Type{<:AbstractEvent}) = Base.HasEltype()

Base.iterate(e::AbstractEvent) = iterate(hits(e))
Base.iterate(e::AbstractEvent, state) = iterate(hits(e), state)

function Base.show(io::IO, e::AbstractEvent)
    print(io, "Event(")
    print(io, eventnum(e), ", ", hitcount(e), ", ", primarycount(e), ", ")
    print(IOContext(io, :limit => true, :compact => true), hits(e))
    print(")")
end

function Base.show(io::IO, mime::MIME"text/plain", e::AbstractEvent)
    print(io, typeof(e), " with ")
    print(io, "eventnum: ", eventnum(e), ", hitcount: ", hitcount(e))
    print(io, ", primarycount: ", primarycount(e), " and hits:\n")
    show(IOContext(io, :limit => true), mime, hits(e))
end

energy(event::E) where {E<:AbstractEvent} = sum(energy, hits(event))


## Event ##

struct Event{T} <: AbstractEvent
    eventnum::Int
    hitcount::Int
    primarycount::Int
    hits::T
    function Event{T}(eventnum, hitcount, primarycount, hits) where {T}
        if length(hits) == hitcount
            return new(eventnum, hitcount, primarycount, hits)
        end
        throw(ArgumentError("hitcount $hitcount must equal number of hits $(length(hits))"))
    end
end

function Event(eventnum, hitcount, primarycount, hits::T) where {T}
    Event{T}(eventnum, hitcount, primarycount, hits)
end

function Event{Vector{H}}(eventnum, hitcount, primarycount, hits::AbstractHitIter) where {H}
    Event{Vector{H}}(eventnum, hitcount, primarycount, collect(H, hits))
end

function Base.convert(::Type{Event{Vector{H}}}, e::Event{<:AbstractHitIter}) where {H}
    return Event{Vector{H}}(eventnum(e), hitcount(e), primarycount(e), hits(e))
end

Base.eltype(::Type{Event{T}}) where {T} = eltype(T)

hits(e::Event) = e.hits
hitcount(e::Event) = e.hitcount
eventnum(e::Event) = e.eventnum
primarycount(e::Event) = e.primarycount
