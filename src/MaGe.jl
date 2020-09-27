module MaGe

using Parsers

import Base

# Hits
export Hit, location, energy, time, particleid, trackid, trackparentid

# Events
export Event, hits, hitcount, eventnum, primarycount

# For FileIO someday: add_format(format"ROOTHITS", (), ".root.hits", [:MaGe])

include("Event.jl")
include("root-hit-files.jl")

end # module
