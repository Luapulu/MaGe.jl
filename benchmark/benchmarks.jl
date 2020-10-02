using MaGe, BenchmarkTools
using Statistics: mean

const eventpath = realpath(joinpath(dirname(pathof(MaGe)), "..", "test", "test.root.hits"))

SUITE = BenchmarkGroup()

SUITE["meta"] = @benchmarkable MaGe.parse_meta(s) setup=(s = IOBuffer("624 119 3\n")) evals=1

hitbuffer = IOBuffer("1.60738 -2.07026 -201.594 0.1638 0 22 187 4 physiDet\n")
SUITE["hit"] = @benchmarkable MaGe.parse_hit(s) setup=(s = copy(hitbuffer)) evals=1

SUITE["read_event"] = @benchmarkable read(MaGe.loadstreaming($eventpath), Event{Vector{Hit}}) evals=1

SUITE["read_file"] = @benchmarkable MaGe.load($eventpath; T=Event{Vector{Hit}}) evals=1

e = first(MaGe.loadstreaming(eventpath))
SUITE["energy"] = @benchmarkable energy($e) evals=1000

SUITE["mean_energy"] = @benchmarkable mean(energy, MaGe.loadstreaming($eventpath)) evals=1

getfirstloc(e::MaGe.AbstractEvent) = location(first(hits(e)))
SUITE["collect_first_locs"] = @benchmarkable map(getfirstloc, MaGe.loadstreaming($eventpath)) evals=1
