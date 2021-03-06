# MaGe.jl

MaGe.jl provides basic functionality for reading and analysing results from the MaGe simulation framework in julia.

Currently, only the Dario output scheme is supported.

## Usage

To load an entire .root.hits file use:

```julia
julia> using MaGe

julia> events = MaGe.load("path-to-file.root.hits"); e = events[1]
Event{Array{Hit,1}} with eventnum: 624, hitcount: 119, primarycount: 3 and hits:
119-element Array{Hit,1}:
 Hit(1.60738, -2.07026, -201.594, 0.1638, 0.0, 22, 187, 4)
 Hit(1.91771, -2.52883, -201.842, 0.24458, 0.0, 22, 187, 4)
 Hit(2.1231, -2.6302, -201.701, 0.12938, 0.0, 22, 187, 4)
 Hit(2.25275, -2.73212, -202.699, 0.17925, 0.0, 22, 187, 4)
 Hit(2.20297, -2.89408, -202.658, 0.125, 0.0, 22, 187, 4)
 Hit(2.20865, -2.90222, -202.659, 0.01478, 0.0, 22, 244, 187)
 ⋮
 Hit(1.60707, -2.06902, -201.597, 0.872949, 0.0, 11, 273, 235)
 Hit(1.60703, -2.06837, -201.596, 2.94965, 0.0, 11, 272, 235)
 Hit(1.60702, -2.06837, -201.596, 0.273757, 0.0, 11, 272, 235)
 Hit(1.60701, -2.06825, -201.596, 2.29979, 0.0, 11, 271, 235)
 Hit(1.60712, -2.06936, -201.595, 3.3094, 0.0, 11, 270, 235)
 Hit(1.60714, -2.06979, -201.594, 1.09771, 0.0, 11, 269, 235)
```

You can parse the file one event at a time with:

```julia
MaGe.loadstreaming("path-to-file.root.hits") do stream
    for event in stream
        # Do something with the event
    end
end
```

Or, equivalently:

```julia
MaGe.loadstreaming("path-to-file.root.hits") do stream
    while !eof(stream)
        event = read(stream)
        # Do something with the event
    end
end
```

Both `loadstreaming`, when used with `do` syntax, and `load` ensure the file is closed after use. However, if an IO stream is passed to either function, the stream will not be closed automatically.

An event has the following interface:

```julia
julia> energy(e)
510.99882859999997

julia> eventnum(e)
624

julia> hitcount(e)
119

julia> primarycount(e)
3
```

An event is made up of hits. Access them by iterating:

```julia
for hit in e
    # Do something with the hit
end
```

or by getting the underlying collection (a vector in this case):

```julia
julia> hits(e)
119-element Array{Hit,1}:
 Hit(1.60738, -2.07026, -201.594, 0.1638, 0.0, 22, 187, 4)
 Hit(1.91771, -2.52883, -201.842, 0.24458, 0.0, 22, 187, 4)
 Hit(2.1231, -2.6302, -201.701, 0.12938, 0.0, 22, 187, 4)
 Hit(2.25275, -2.73212, -202.699, 0.17925, 0.0, 22, 187, 4)
 Hit(2.20297, -2.89408, -202.658, 0.125, 0.0, 22, 187, 4)
 Hit(2.20865, -2.90222, -202.659, 0.01478, 0.0, 22, 244, 187)
 ⋮
 Hit(1.60707, -2.06902, -201.597, 0.872949, 0.0, 11, 273, 235)
 Hit(1.60703, -2.06837, -201.596, 2.94965, 0.0, 11, 272, 235)
 Hit(1.60702, -2.06837, -201.596, 0.273757, 0.0, 11, 272, 235)
 Hit(1.60701, -2.06825, -201.596, 2.29979, 0.0, 11, 271, 235)
 Hit(1.60712, -2.06936, -201.595, 3.3094, 0.0, 11, 270, 235)
 Hit(1.60714, -2.06979, -201.594, 1.09771, 0.0, 11, 269, 235)
```

A hit has the following interface:

```julia
julia> h = hits(e)[1]
Hit(1.60738, -2.07026, -201.594, 0.1638, 0.0, 22, 187, 4)

julia> location(h)
(1.60738, -2.07026, -201.594)

julia> energy(h)
0.1638

julia> time(h)
0.0

julia> particleid(h)
22

julia> trackid(h)
187

julia> trackparentid(h)
4
```
