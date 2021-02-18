function paramtypes(::Type{D}) where D<:Distribution 
    isconcretetype(D) || error("Expected a concrete distibution type," *
        " Did you specify all type parameters, e.g. $D{Float64}?")
    D.types
end
function tupleofvectype(::Type{D}) where D<:Distribution 
    # https://discourse.julialang.org/t/allocations-in-comprehensions/21309/3
    V = Tuple{ntuple(
        i -> Vector{Union{Missing,paramtypes(D)[i]}}, length(paramtypes(D)))...}
end


"""
    vectuptotupvec(vectup)

Typesafe convert from Vector of Tuples to Tuple of Vectors.

# Arguments
* `vectup`: A Vector of identical Tuples 

# Examples
```jldoctest; output=false, setup = :(using Distributions,LogNormals)
vectup = [(1,1.01, "string 1"), (2,2.02, "string 2")] 
vectuptotupvec(vectup) == ([1, 2], [1.01, 2.02], ["string 1", "string 2"])
# output
true
```
"""
function vectuptotupvec(vectup::AbstractVector{TT}) where 
    {TT<:Union{Missing,NTuple{N, Any}}} where N
    v1 = first(skipmissing(vectup))
    types = typeof.(v1)
    imiss = findall(ismissing, vectup) # unfortunately allocating
    if length(imiss) != 0
        # replace missing by a tuple of correct type (replaced later be missings)
        # because there is no missing of correct type during getindex
        vectupc = mappedarray((x -> ismissing(x) ? v1 : x), vectup)
        function f(i) 
            v = allowmissing(
                getindex.(vectupc,i))::Vector{Union{Missing,types[i]}}
            v[imiss] .= missing
            v
        end
        ntuple(f, length(v1))
    else
        ntuple((i ->
            allowmissing(getindex.(vectup,i))::Vector{Union{Missing,types[i]}}
        ), length(v1))
    end
end

"""
    AbstractDistributionVector{D <: Distribution}

Is any type able represent a vector of distribution of the same type.
This corresponds to a sequence of random variables, each characterized
by the same type of distribution but with different parameters. 
This allows aggregating functions to work, for
example, computing the distribution of the sum of random variables by 
[`sum(dv::AbstractDistributionVector)`](@ref).

It is parametrized by `D <: Distribution` defining the type of the distribution
used for all the random variables.

Items may be missing. Hence the element type of the iterator is 
`Union{Missing,D}`.

AbstractDistributionVector
- is iterable
- has length and index access, i.e. `dv[i]::D`
- access to entire parameter vectors: `params(dv,Val(i))`
- conversion of Tuple of Vectors: `params(dv)`
- array of random numbers: `rand(n, dv)`: adding one 
  dimension that represents across random variables

Specific implementations,  need
to implement at minimum methods `length` and `getindex`, and `params`.

There are two standard implementations:
- [`SimpleDistributionVector`](@ref): fast indexing but slower `params` method 
- [`ParamDistributionVector`](@ref): possible allocations in indexing but 
  faster `params`

# Examples
```jldoctest; output = false, setup = :(using Distributions,LogNormals)
dmn1 = MvNormal([0,0,0], 1)
dmn2 = MvNormal([1,1,1], 2)
dv = SimpleDistributionVector(dmn1, dmn2, missing, missing);
sample = rand(dv,2);
# 4 distr, each 2 samples of length 3
size(sample) == (3,2,4)
# output
true
```
"""
abstract type AbstractDistributionVector{D <: Distribution} end

Base.eltype(::Type{<:AbstractDistributionVector{D}}) where D = Union{Missing,D}

function Base.iterate(dv::AbstractDistributionVector, state=1) 
    state > length(dv) ? nothing : (dv[state], state+1)
end

function Base.iterate(rds::Iterators.Reverse{AbstractDistributionVector}, 
    state=length(rds.itr))  
    state < 1 ? nothing : (rds.itr[state], state-1)
end
Base.firstindex(dv::AbstractDistributionVector) = 1
Base.lastindex(dv::AbstractDistributionVector) = length(dv)
Base.getindex(dv::AbstractDistributionVector, i::Number) = dv[convert(Int, i)]

function StatsBase.params(dv::AbstractDistributionVector{D}, ::Val{i}) where 
    {D,i}
    # need to help compile to determine the type of tupvec
    T = tupleofvectype(D).parameters[i]
    allowmissing(collect(passmissing(getindex).(passmissing(params).(dv),i)))::T
end

function Random.rand(dv::AbstractDistributionVector, n::Integer) 
    x1 = rand(first(skipmissing(dv)), n)
    xm = Fill(missing,size(x1))
    #xm = fill(missing,size(x1))
    fmiss(x)::Union{typeof(xm),typeof(x1)} = (ismissing(x) ? xm : rand(x,n))
    vecarr = convert(Vector{Union{typeof(xm),typeof(x1)}}, fmiss.(dv))::Vector{Union{typeof(xm),typeof(x1)}}
    VectorOfArray(vecarr)
end
function Random.rand(dv::AbstractDistributionVector{D}) where {F,S,D<:Distribution{F,S}}
    x1 = rand(first(skipmissing(dv))) 
    xm = Fill(missing,size(x1))
    #xm = fill(missing,size(x1))
    fmiss(x)::Union{typeof(xm),typeof(x1)} = (ismissing(x) ? xm : rand(x)) 
    vecarr = convert(Vector{Union{typeof(xm),typeof(x1)}}, fmiss.(dv))::Vector{Union{typeof(xm),typeof(x1)}}
    F <: Univariate ? vecarr : VectorOfArray(vecarr)
end

# Random.rand(dv::AbstractDistributionVector, dim1::Int) = 
#     rand(GLOBAL_RNG, dv, dim1)
# Random.rand(rng::AbstractRNG, dv::AbstractDistributionVector{D}, 
#     dim1::Int) where D = [rand(dv) for i in 1:dim1]


## SimpleDistributionVector   
"""
    SimpleDistributionVector{D <: Distribution, V}

Is an Vector-of-Distribution based implementation of 
[`AbstractDistributionVector`](@ref).

Vector of random var can be created by 
- specifying the distributions as arguments.
```jldoctest; output = false, setup = :(using Distributions,LogNormals)
d1 = LogNormal(log(110), 0.25)
d2 = LogNormal(log(100), 0.15)
dv = SimpleDistributionVector(d1, d2, missing);
isequal(params(dv, Val(1)), [log(110), log(100), missing])
# output
true
```

- providing the Type of distribution and vectors of each parameter
```jldoctest; output = false, setup = :(using Distributions,LogNormals)
mu = [1.1,1.2,1.3]
sigma = [1.01, 1.02, missing]
dv = SimpleDistributionVector(LogNormal{eltype(mu)}, mu, sigma);
isequal(params(dv, Val(1)), [1.1,1.2,missing])
# output
true
```
Note that if one of the parameters is missing, then the entire entry of
the distribution is marked missing.

Since Distributions are stored directly, indexing passes a reference.
However, getting parameter vectors, required iterating all distributions, 
and allocating a new vector.
"""
struct SimpleDistributionVector{D <: Distribution, V <: AbstractVector} <: 
    AbstractDistributionVector{D} 
    dvec::V
    # inner constructor checking ?
end

function SimpleDistributionVector(::Type{D}, dvec::V) where 
{D<:Distribution,  V<:AbstractVector} 
    isconcretetype(D) || error("Expected a concrete distibution type," *
        " Did you specify all type parameters, e.g. $D{Float64}?")
    Missing <: eltype(V) || error(
        "Expected type of parameters to allow for missing." *
        " Can you use 'allowmissing' in constructing the " *
        "SimpleDistributionVector?")
    eltype(V) <: Union{Missing, <:D} || error(
        "Expected type of parameters of 'Union{Missing, $(D)}' "*
        " but got $(eltype(V)).")
    SimpleDistributionVector{D, V}(dvec)
end

function SimpleDistributionVector(dv::Vararg{Union{Missing,D},N}) where 
    {D<:Distribution, N} 
    N == 0 && error(
        "Provide at least one argument, i.e. distribtution," *
        "i n SimpleDistributionVector(x...).")
    d1 = first(skipmissing(dv))
    dvec = collect(Union{Missing, typeof(d1)}, dv)::Vector{Union{Missing, typeof(d1)}}
    SimpleDistributionVector(D, allowmissing(dvec))
end

function SimpleDistributionVector(::Type{D}, pvec::Vararg{Any,N}) where 
    {D<:Distribution, N} 
    # must use information from D to make return type stable
    pvecm = (x -> allowmissing(x)).(pvec)::tupleofvectype(D)
    dvec = allowmissing(collect(zip(pvecm...)))
    # if one parameter has missing, the entire tuple must be set to missing
    anymissing(tup) = any(ismissing.(tup))
    imiss = anymissing.(dvec)
    tupm = dvec[findfirst(.!imiss)]
    dvec[imiss] .= Ref(tupm)
    dv = allowmissing(collect(D(x...) for x in dvec))
    dv[imiss] .= missing
    SimpleDistributionVector(D, dv)
end


Base.length(dv::SimpleDistributionVector) = length(dv.dvec)

function Base.getindex(dv::SimpleDistributionVector{D,V},i::Int) where {D,V}
    dv.dvec[i]::Union{Missing, D}
end
Base.getindex(dv::SimpleDistributionVector{D, V}, I) where {D,V} = 
    SimpleDistributionVector{D,V}(dv.dvec[I])
    #Base.typename(DV).wrapper((dv[i] for i in I)...)


# params(i) already defined as default in AbstractDistributionVector
# function StatsBase.params(dv::SimpleDistributionVector, i::Integer) 
#    # mappedarray(e -> passmissing(getindex)(e,i), dv.dvec)
#    # currentl does not work, see 
# https://github.com/JuliaArrays/MappedArrays.jl/issues/40
#    passmissing(getindex).(passmissing(params).(dv.dvec),i)
# end

function StatsBase.params(dv::SimpleDistributionVector{D,V}) where {D,V}
    # passmissing(...) not typestable
    #vectuptotupvec(passmissing(params).(dv.dvec)) 
    # also not typestable:
    #vectup = mappedarray((x -> ismissing(x) ? missing : params(x)),dv.dvec)
    v1 = params(first(skipmissing(dv.dvec)))
    types = typeof.(v1)
    imiss = findall(ismissing, dv.dvec) # unfortunately allocating
    if length(imiss) != 0
        # replace missing by a tuple of correct type (replaced later by missing)
        # because there is no missing of correct type during getindex
        vectupc = mappedarray((x -> ismissing(x) ? v1 : params(x)), dv.dvec)
        function f(i) 
            v = allowmissing(
                getindex.(vectupc,i))::Vector{Union{Missing,types[i]}}
            v[imiss] .= missing
            v
        end
        ntuple(f, length(v1))
    else
        ntuple((i ->
            allowmissing(
                getindex.(params.(dv.dvec),i))::Vector{Union{Missing,types[i]}}
        ), length(v1))
    end
end


## ParamDistributionVector
"""
    ParamDistributionVector{D <: Distribution, V}
   
Is an Tuple of Vectors based implementation of 
[`AbstractDistributionVector`](@ref).

Vector of random var can be created by 
- specifying the distributions as arguments with some overhead of converting
  the Distributions to vectors of each parameter
```jldoctest; output = false, setup = :(using Distributions,LogNormals)
d1 = LogNormal(log(110), 0.25)
d2 = LogNormal(log(100), 0.15)
dv = ParamDistributionVector(d1, d2, missing);
isequal(params(dv, Val(1)), [log(110), log(100), missing])
# output
true
```

- providing the Type of distribution and vectors of each parameter
```jldoctest; output = false, setup = :(using Distributions,LogNormals)
mu = [1.1,1.2,1.3]
sigma = [1.01, 1.02, missing]
dv = ParamDistributionVector(LogNormal{eltype(mu)}, mu, sigma);
ismissing(dv[3])
isequal(params(dv, Val(1)), [1.1,1.2,1.3]) # third still not missing here
# output
true
```
Note that if one of the parameters for entry `i` is missing, then `dv[i]`
is missing.

Since distributions are stored by parameter vectors, the acces to these
vectors is just passing a reference.
Indexing, will create Distribution types.
"""
struct ParamDistributionVector{D <: Distribution, V <: Tuple} <: 
    AbstractDistributionVector{D} 
    params::V
    # inner constructor checking ?
end

function ParamDistributionVector(::Type{D}, params::V) where 
{D<:Distribution,  V<:Tuple} 
    isconcretetype(D) || error("Expected a concrete distibution type," *
        " Did you specify all type parameters, e.g. $D{Float64}?")
    all(map((x -> x <: AbstractVector), V.parameters)) || error(
        "Expected all entries in Tuple param to be AbstractVectors.")
    all(map((x -> Missing <: eltype(x)), V.parameters)) || error(
        "Expected type of each vector in params to allow for missing.")
    lenparams = map(length, params)
    all(map(x -> x == first(lenparams), lenparams)) || error(
        "Expected all vectors in params tuple to be of the same length.")
    ParamDistributionVector{D, V}(params)
end



function ParamDistributionVector(dtup::Vararg{Union{Missing,D},N}) where 
    {D<:Distribution, N} 
    N == 0 && error(
        "Provide at least one distribution in ParamDistributionVector(x...).")
    # need to help compile to determine the type of tupvec
    tupvec = Tuple(
        allowmissing(
            collect(passmissing(getindex).(passmissing(params).(dtup),i))) 
        for i in 1:length(paramtypes(D)))::tupleofvectype(D)
    ParamDistributionVector(D, tupvec)
end

function ParamDistributionVector(::Type{D}, pvec::Vararg{Any,N}) where 
    {D<:Distribution, N} 
    # cannot constrain first type in VarArg because Array{Int} differst 
    # from Array{Float64}
    # in order to be type-stable type D must be queried for required types
    pvecm = (x -> allowmissing(x)).(pvec)::tupleofvectype(D)
    ParamDistributionVector(D, pvecm)        
end

Base.length(dv::ParamDistributionVector) = length(first(dv.params))

function Base.getindex(dv::ParamDistributionVector{D,V}, 
    i::Int)::Union{Missing, D} where {D,V}
    params_i = getindex.(dv.params, Ref(i))
    any(ismissing.(params_i)) && return missing
    D(params_i...)
end
function Base.getindex(dv::ParamDistributionVector{D, V}, I) where {D,V} 
    tupvec = map(x -> x[I], dv.params)
    ParamDistributionVector{D,V}(tupvec)
    #Base.typename(DV).wrapper((dv[i] for i in I)...)
end


function StatsBase.params(dv::ParamDistributionVector{D,V}, ::Val{i}) where 
    {D,V,i}
    # if types of parameters differ, then a union type is returned -> need Val
    dv.params[i]
end

StatsBase.params(dv::ParamDistributionVector) = dv.params

