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
    meta_stream = IOBuffer("624 119 3\n")
    @test MaGe.parse_meta(meta_stream) == (624, 119, 3)

    hitstream = IOBuffer(
        """
        1.60738 -2.07026 -201.594 0.1638 0 22 187 4 physiDet
        1.91771 -2.52883 -201.842 0.24458 0 22 187 4 physiDet
        """)

    @test MaGe.parse_hit(hitstream) == Hit(1.60738, -2.07026, -201.594, 0.1638, 0, 22, 187, 4)
    @test MaGe.parse_hit(hitstream) == Hit(1.91771, -2.52883, -201.842, 0.24458, 0, 22, 187, 4)

    test_stream = IOBuffer(
        """
        624 2 3
        1.60738 -2.07026 -201.594 0.1638 0 22 187 4 physiDet
        1.91771 -2.52883 -201.842 0.24458 0 22 187 4 physiDet
        """)
    test_stream2 = copy(test_stream)

    test_reader = MaGe.RootHitReader(test_stream, false)

    e = read(test_reader)
    @test eventnum(e) == 624
    @test hitcount(e) == 2
    @test primarycount(e) == 3

    parsed_hits = [
        MaGe.parse_hit(IOBuffer("1.60738 -2.07026 -201.594 0.1638 0 22 187 4 physiDet")),
        MaGe.parse_hit(IOBuffer("1.91771 -2.52883 -201.842 0.24458 0 22 187 4 physiDet"))
    ]

    e2 = Event{Vector{Hit}}(e)

    for i in 1:2
        @test hits(e2)[i] == parsed_hits[i]
    end

    @test isnothing(iterate(test_reader))

    e3 = read(MaGe.loadstreaming(test_stream2), Event{Vector{Hit}})
    @test typeof(e3) == Event{Vector{Hit}}

    eventpath = realpath(joinpath(dirname(pathof(MaGe)), "..", "test", "test.root.hits"))

    @test MaGe.is_root_hit_file(eventpath)

    events = MaGe.load(eventpath)

    lastevent = events[end]

    @test eventnum(lastevent) == 999851

    @test hitcount(lastevent) == 319

    @test primarycount(lastevent) == 4

    @test hits(lastevent)[1] == Hit(-1.2325, -2.44103, -196.814, 0.07764, 0.0, 22, 9, 6)

    @test hits(lastevent)[end] == Hit(-1.18915, -2.28214, -198.958, 8.4419, 0.0, 11, 165, 16)

    badpath = realpath(joinpath(dirname(pathof(MaGe)), "..", "test", "bad.root.hits"))
    badreader = MaGe.loadstreaming(badpath)
    @test_throws Parsers.Error Event{Vector{Hit}}(read(badreader))
    @test_throws Parsers.Error read(badreader)
end
