using MaGe, BenchmarkTools
using Statistics: mean

const eventpath = realpath(joinpath(dirname(pathof(MaGe)), "..", "test", "test.root.hits"))

SUITE = BenchmarkGroup()

SUITE["read_event"] = @benchmarkable read(MaGe.loadstreaming($eventpath), Event{Vector{Hit}})

SUITE["load_file"] = @benchmarkable MaGe.load($eventpath; T=Event{Vector{Hit}})

e = first(MaGe.loadstreaming(eventpath))
SUITE["energy"] = @benchmarkable energy($e)

SUITE["mean_energy"] = @benchmarkable mean(energy, MaGe.loadstreaming($eventpath))

getfirstloc(e::MaGe.AbstractEvent) = location(first(hits(e)))
SUITE["collect_first_locs"] = @benchmarkable map(getfirstloc, MaGe.loadstreaming($eventpath))
