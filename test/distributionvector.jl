using LogNormals
using Missings, Distributions, Test

@testset "DistributionVector" begin

@testset "vectuptotupvec" begin
    vectup = [(1,1.01, "string 1"), (2,2.02, "string 2")] 
    tupvec = @inferred vectuptotupvec(vectup)
    #@code_warntype vectuptotupvec(vectup)
    @test tupvec == ([1, 2], [1.01, 2.02], ["string 1", "string 2"])  
    # empty not allowed
    @test_throws Exception tupvec = vectuptotupvec([])
    # first missing
    vectupm = [missing, (1,1.01, "string 1"), (2,2.02, "string 2")] 
    vectuptotupvec(vectupm)
    tupvecm = @inferred vectuptotupvec(vectupm)
    @test ismissing(vectupm[1]) # did not change underlying vector
    #@code_warntype vectuptotupvec(vectupm)
    @test isequal(tupvecm, ([missing, 1, 2], [missing, 1.01, 2.02], [missing, "string 1", "string 2"]))
    # do not allow tuples of different length
    vectupm = [(1,1.01, "string 1"), (2,2.02, "string 2",:asymbol)] 
    @test_throws Exception tupvecm = vectuptotupvec(vectupm)
    # do not allow tuples of differnt types - note the Float64 in first entry
    vectupm = [(1.00,1.01, "string 1"), (2,2.02, "string 2",:asymbol)] 
    @test_throws Exception tupvecm = vectuptotupvec(vectupm)
end;

@testset "SimpleDistributionVector" begin
    n = [1,2,3]
    p = [.01, .02, .03]
    a = map(x -> Binomial(x...), zip(n,p))
    dv = dv0 = SimpleDistributionVector(Binomial{Float64}, allowmissing(a))
    nm = allowmissing(n); nm[1] = missing
    am = allowmissing(a); am[1] = missing
    dvm = SimpleDistributionVector(Binomial{Float64}, am)
    @testset "checking constructors" begin
        # not using allowmissing
        @test_throws ErrorException SimpleDistributionVector(Binomial, a) 
        # not allowing others than tuples
        @test_throws ErrorException SimpleDistributionVector(Binomial, allowmissing([1,2])) 
        # not allowing for Tuples of different length
        # already coverey by Vector{T}
    end;    
    @testset "iterator nonmissing" begin
        @test @inferred length(dv) == 3
        d = @inferred Missing dv[1]
        @test isa(d, Binomial{Float64})
        @test params(d) == (n[1], p[1])
        darr = [d for d in dv]
    end;    
    @testset "iterator missing" begin
        @test @inferred length(dvm) == 3
        @test ismissing(@inferred Binomial dvm[1])
        d = @inferred Missing dvm[2]
        @test isa(d, Binomial{Float64})
        @test params(d) == (n[2], p[2])
        darr = [d for d in dvm]
        ismissing(darr[1])
    end; 
    @testset "constructor with several Distributions" begin
        d1 = Binomial(1, 0.25)
        d2 = Binomial(2, 0.15)
        dv = @inferred SimpleDistributionVector(d1, d2);
        @test @inferred Missing dv[1] == d1
        # empty not allowed
        @test_throws Exception SimpleDistributionVector()
        # different types not allowed
        @test_throws MethodError SimpleDistributionVector(d1, d2, Normal());
        # with missing 
        dv = @inferred SimpleDistributionVector(d1, d2, missing);
        @test ismissing(dv[3])
        # type no defined if provided missing
        @test_throws Exception dv = SimpleDistributionVector(missing);
    end;
    @testset "constructor with parameter vectors" begin
        dv = @inferred SimpleDistributionVector(Binomial{Float64}, n, p)
        # broadcast slightly slower and more allocations than generator on vectup returned from dv
        #@btime SimpleDistributionVector((ismissing(x) ? missing : Binomial(x...) for x in $dv)...)
        #@btime SimpleDistributionVector((x -> ismissing(x) ? missing : Binomial(x...)).($dv)...)
        # @btime begin
        #     a = collect((x -> ismissing(x) ? missing : Binomial(x...)).($dv))
        #     SimpleDistributionVector(Binomial{Float64}, a)
        # end
        @test params(first(dv)) == (n[1], p[1])
        @test params(dv, Val(1)) == n
        @test params(dv, Val(2)) == p
        # when one parameter has missing, the entire tuple must be set to missing
        dv = @inferred SimpleDistributionVector(Binomial{Float64}, nm, p)
        @test ismissing(dv[1])
        # need concrete type, here test missing {Float64}
        @test_throws ErrorException SimpleDistributionVector(Binomial, n, p)
    end;
    @testset "accessing parameters as array" begin
        @test @inferred(params(dv0,Val(1))) == n
        @test @inferred(params(dv0,Val(2))) == p
        # missing
        @test ismissing(params(dvm, Val(1))[1]) 
        @test params(dvm, Val(1))[2:3] == n[2:3]
        @test_throws BoundsError params(dv0,Val(3))
    end;
    @testset "Multivariate distribution with complex parameter types" begin
        #dmn1 = MvNormal(3, 1) # does not work because its of different specific type
        dmn1 = MvNormal([0,0,0], 1)
        dmn2 = MvNormal([1,1,1], 2)
        #params(dmn1), params(dmn2)
        dv = @inferred SimpleDistributionVector(dmn1, dmn2, missing);
        @test @inferred Missing dv[1] == dmn1
        @test @inferred Missing dv[2] == dmn2
        @test ismissing(dv[3])
        @inferred params(dv, Val(1))
        @test nonmissingtype(eltype(@inferred Missing params(dv, Val(1)))) <: AbstractVector
        @test nonmissingtype(eltype(@inferred Missing params(dv, Val(2)))) <: AbstractMatrix
    end;
    @testset "Tuple of all parameter vectors" begin
        tupvec = @inferred params(dv0)
        @test tupvec == (allowmissing(n), allowmissing(p))
        tupvec = @inferred params(dvm)
        @test isequal(tupvec[1], (allowmissing(nm)))
        @test isequal(tupvec[2][2:end], (allowmissing(p)[2:end]))
    end;
    @testset "rand" begin
        x = @inferred rand(dv0)
        @test size(x) == (3,)
        x = @inferred rand(dv0,5)
        @test size(x) == (5,)
        @test size(x[1]) == (3,)
        #@code_warntype rand(dv0)
        # with missings
        x = @inferred rand(dvm,5)
        @test size(x) == (5,)
        @test size(x[1]) == (3,)
        @test ismissing(x[2][1])
    end;
end; # testset "SimpleDistributionVector"

@testset "ParamDistributionVector" begin
    n = [1,2,3]
    p = [.01, .02, .03]
    a0 = (n,p)
    a = ((allowmissing(n), allowmissing(p)))
    typeof(a).parameters[1]
    @test all(map((x -> x <: AbstractVector), typeof(a).parameters))
    @test all(map((x -> Missing <: eltype(x)), typeof(a).parameters))
    @test !all(map((x -> Missing <: eltype(x)), typeof(a0).parameters))
    first(skipmissing(a))
    lena = map(length, a)
    all(map(x -> x == first(lena), lena))
    dv = dv0 = ParamDistributionVector(Binomial{Float64}, a)
    nm = allowmissing(copy(n)); nm[1] = missing
    am = (nm, allowmissing(p))
    dvm = ParamDistributionVector(Binomial{Float64}, am)
    @testset "checking constructors" begin
        # not using allowmissing
        @test_throws ErrorException ParamDistributionVector(Binomial, a0) 
        # not allowing others than vectors
        @test_throws ErrorException ParamDistributionVector(Binomial{Float64}, (nm, "bla"))
        # not allowing for vectors of different length
        @test_throws ErrorException ParamDistributionVector(Binomial{Float64}, (nm, nm[1:2]))
    end;    
    @testset "iterator nonmissing" begin
        @test @inferred length(dv) == 3
        d = @inferred Missing dv[1]
        @test isa(d, Binomial{Float64})
        @test params(d) == (n[1], p[1])
        darr = [d for d in dv]
    end;    
    @testset "iterator missing" begin
        @test @inferred length(dvm) == 3
        @test ismissing(@inferred Binomial dvm[1])
        d = @inferred Missing dvm[2]
        @test isa(d, Binomial{Float64})
        @test params(d) == (n[2], p[2])
        darr = [d for d in dvm]
        ismissing(darr[1])
    end; 
    @testset "constructor with several Distributions" begin
        d1 = Binomial(1, 0.25)
        d2 = Binomial(2, 0.15)
        td = (d1, d2)
        dv = @inferred ParamDistributionVector(d1, d2);
        @test @inferred Missing dv[1] == d1
        # empty not allowed
        @test_throws Exception ParamDistributionVector()
        # different types not allowed
        @test_throws MethodError ParamDistributionVector(d1, d2, Normal());
        # with missing 
        dv = @inferred ParamDistributionVector(d1, d2, missing);
        @test ismissing(dv[3])
        # type no defined if provided missing
        @test_throws Exception dv = ParamDistributionVector(missing);
    end;
    @testset "constructor with parameter vectors" begin
        dv = @inferred ParamDistributionVector(Binomial{Float64}, n, p)
        d1 = @inferred Missing dv[1]
        @test params(d1) == (n[1], p[1])
        # when one parameter has missing, the entire tuple must be set to missing
        dv = @inferred ParamDistributionVector(Binomial{Float64}, nm, p)
        @test ismissing(dv[1])
        # need concrete type, here test missing {Float64}
        @test_throws ErrorException ParamDistributionVector(Binomial, n, p)
    end;
    @testset "accessing parameters as array" begin
        @test @inferred(params(dv0,Val(1))) == n
        @test params(dv0,Val(2)) == p
        # missing
        @test ismissing(params(dvm, Val(1))[1]) 
        @test params(dvm, Val(1))[2:3] == n[2:3]
        @test_throws BoundsError params(dv0,Val(3))
    end;
    @testset "Multivariate distribution with complex parameter types" begin
        #dmn1 = MvNormal(3, 1) # does not work because its of different specific type
        dmn1 = MvNormal([0,0,0], 1)
        dmn2 = MvNormal([1,1,1], 2)
        #params(dmn1), params(dmn2)
        dv = @inferred ParamDistributionVector(dmn1, dmn2, missing)
        typeof(dv).parameters[1]
        D = typeof(dv).parameters[1]
        #tupleofvectype(D).parameters[1]
        #tupleofvectype(D).parameters[2]
        @test nonmissingtype(eltype(@inferred params(dv, Val(1)))) <: AbstractVector
        #@code_warntype(params(dv, Val(1)))
        @test nonmissingtype(eltype(@inferred params(dv, Val(2)))) <: AbstractMatrix
    end;
    @testset "Tuple of all parameter vectors" begin
        tupvec = @inferred params(dv0)
        @test tupvec == (allowmissing(n), allowmissing(p))
        tupvec = @inferred params(dvm)
        @test isequal(tupvec, (allowmissing(nm), allowmissing(p)))
    end;
    @testset "passing vector by reference" begin
        dv = ParamDistributionVector(Binomial(1, 0.7));
        n = params(dv, Val(1)); # reference
        n[1] = 2
        @test params(dv[1])[1] == 2 # note has changed
        # Binomial is immutable cannot changed
        # dv[1].μ = 3
    end;
    @testset "rand" begin
        x = @inferred rand(dv0)
        @test size(x) == (3,)
        x = @inferred rand(dv0,5)
        @test size(x) == (5,)
        @test size(x[1]) == (3,)
        #@code_warntype rand(dv0)
        # with missings
        x = @inferred rand(dvm,5)
        @test size(x) == (5,)
        @test size(x[1]) == (3,)
        @test ismissing(x[2][1])
    end;
end; #@testset "ParamDistributionVector"

end; # @testset "DistributionVector"