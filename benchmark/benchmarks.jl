using MaGe, BenchmarkTools
using Statistics: mean

const eventpath = realpath(joinpath(dirname(pathof(MaGe)), "..", "test", "test.root.hits"))

SUITE = BenchmarkGroup()

SUITE["read_event"] = @benchmarkable read(MaGe.loadstreaming($eventpath), Event{Vector{Hit}})

SUITE["load_file"] = @benchmarkable MaGe.load($eventpath; T=Event{Vector{Hit}})

e = MaGe.loadstreaming(first, eventpath)
SUITE["energy"] = @benchmarkable energy($e)

SUITE["mean_energy"] = @benchmarkable MaGe.loadstreaming($eventpath) do es
    energies = Vector{Float64}()
    while !eof(es)
        e = read(es, Event{MaGe.RootHitIter})
        push!(energies, energy(e))
    end
    return mean(energies)
end

getfirstloc(e::MaGe.AbstractEvent) = location(first(hits(e)))
SUITE["collect_first_locs"] = @benchmarkable map(getfirstloc, MaGe.loadstreaming($eventpath))
