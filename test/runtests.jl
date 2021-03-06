using Test, Parsers, MaGe

@testset "Hits" begin
    h = Hit(1.1, 2.2, 3.3, 4.4, 5.5, 6, 7, 8)

    @test location(h) == (1.1, 2.2, 3.3)
    @test energy(h) == 4.4
    @test time(h) == 5.5
    @test particleid(h) == 6
    @test trackid(h) == 7
    @test trackparentid(h) == 8

    @test_throws InexactError Hit(1, 2, 3, 4, 5, 1.1, 2.2, 3.3)
end


@testset "Events" begin
    v = [Hit(i*i, sqrt(i), 3.5, 4, 0.5, 1, 2, 3) for i in 1:5]
    e = Event(1, 5, 2, v)

    @test eltype(typeof(e)) == Hit

    @test energy(e) == 4*5

    @test hits(e) == v
    @test eventnum(e) == 1
    @test length(e) == hitcount(e) == 5
    @test primarycount(e) == 2

    # Wrong number of hits for hitcount
    @test_throws ArgumentError Event(1, 3, 2, v)
end


@testset "Parsing .root.hits files" begin
    path = tempname()

    open(path, "w") do io
        truncate(io, 0)
        write(io, "123 456 789\n")
    end

    open(path) do io
        @test MaGe.parse_meta(io) == (123, 456, 789)
    end

    open(path, "w") do io
        truncate(io, 0)
        write(io, "1.2 -2.3 -3.4 4.5 5.6 67891011 121314 1516 physiDet
                  0.11 0.1234321 -333 -0.44 0.001 1 2 3 physiDet")
    end

    open(path) do io
        @test MaGe.parse_hit(io) == Hit(1.2, -2.3, -3.4, 4.5, 5.6, 67891011, 121314, 1516)
        @test MaGe.parse_hit(io) == Hit(0.11, 0.1234321, -333, -0.44, 0.001, 1, 2, 3)
    end

    open(path, "w") do io
        truncate(io, 0)
        write(io, "624 2 3
                  1.60738 -2.07026 -201.594 0.1638 0 22 187 4 physiDet
                  1.91771 -2.52883 -201.842 0.24458 0 22 187 4 physiDet")
    end

    testreader = MaGe.loadstreaming(path)

    e = read(testreader)
    @test eventnum(e) == 624
    @test hitcount(e) == 2
    @test primarycount(e) == 3

    @test hits(e)[1] == Hit(1.60738, -2.07026, -201.594, 0.1638, 0, 22, 187, 4)
    @test hits(e)[2] == Hit(1.91771, -2.52883, -201.842, 0.24458, 0, 22, 187, 4)

    for (h1, h2) in zip(e, hits(e))
        @test h1 === h2
    end

    @test isnothing(iterate(testreader))

    testpath = realpath(joinpath(dirname(pathof(MaGe)), "..", "test", "test.root.hits"))

    @test MaGe.is_root_hit_file(testpath)

    events = MaGe.load(testpath)

    lastevent = events[end]

    @test eventnum(lastevent) == 999851

    @test hitcount(lastevent) == 319

    @test primarycount(lastevent) == 4

    @test hits(lastevent)[1] == Hit(-1.2325, -2.44103, -196.814, 0.07764, 0.0, 22, 9, 6)

    @test hits(lastevent)[end] == Hit(-1.18915, -2.28214, -198.958, 8.4419, 0.0, 11, 165, 16)

    @test MaGe.loadstreaming(testpath) do stream
        for e in stream
            if eventnum(e) == 999851
                return hitcount(e) == 319
            end
        end
        return false
    end

    @test MaGe.loadstreaming(testpath) do stream
        while !eof(stream)
            e = read(stream)
            if eventnum(e) == 999851
                return hitcount(e) == 319
            end
        end
        return false
    end

    @test all(extrema(energy, MaGe.loadstreaming(testpath)) .≈ (17.05186, 3068.0469217))

    badpath = realpath(joinpath(dirname(pathof(MaGe)), "..", "test", "bad.root.hits"))
    badreader = MaGe.loadstreaming(badpath)
    @test_throws Parsers.Error read(badreader)
    @test_throws Parsers.Error read(badreader)
end
