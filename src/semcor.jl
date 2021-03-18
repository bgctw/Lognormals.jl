"""
    count_forlags(pred, x, lags)
    count_forlag(pred, x, k::Integer)

Count the number of pairs for lag `k` which fulfil a predicate.

# Arguments
- `pred::Function(x_i,x_iplusk)::Bool`: The predicate to be applied to each pair 
- `x`: The series whose lags are inspected.
- `lags`: An iterator of Integer lag sizes
- `k`: A single lag.

Common case is to compute the number of missings for the autocorrelation:
with predicate `missinginpair(x,y) = ismissing(x) || ismissing(y)`.

"""
function count_forlag(pred,x,k::Integer)
    s = 0
    ax = OffsetArrays.no_offset_view(axes(x,1))
    for i in 1:(length(x)-k)
        if pred(x[ax[i]], x[ax[i+k]]); s += 1; end
    end
    s
end,
function count_forlags(pred, x,lags::AbstractVector) 
    count_forlag.(tuple(pred), tuple(x),lags)
end

"""
    autocor(x::AbstractVector{x::Union{Missing,<:T}, lags, ms::MissingStrategy=PassMissing(); dmean::Bool=true}

Estimate the autocorrelation function accounting for missing values.

# Arguments
- `x`: series, which may contain missing values
- `lags`: Integer vector of the lags for which correlation should be computed
- `ms`: `MissingStrategy`. Defaults to `PassMissing`. Set to `ExactMissing()` to
    divide the sum
   in the formula of the exepected value in the formula for the correlation
   at lag `k` by `n - nmissing` instead of `n`, 
   where `nimissing` is the number of records where there is a missing either
   in the original vector or its lagged version (see [`count_forlags`](@ref)).
- `deman`: if `false`, assume `mean(x)==0`.

If the missing strategy is set to `SkipMissing()` then the computation is faster, 
but it is more strongly biased low with increasing number of missings. 
Note that `StatsBase.autocor` uses devision by `n` instead of 'n-k', the
true length of the vectors correlated at lag `k` resulting in 
low-biased correlations of higher lags for numerical stability reasons.
"""
(@traitfn autocor(x::::!(IsEltypeSuperOfMissing), 
    ms::MissingStrategy; kwargs...) = autocor(x; kwargs...)),
(@traitfn autocor(x::::!(IsEltypeSuperOfMissing), lags::AbstractVector{<:Integer}, 
    ms::MissingStrategy, kwargs...) = autocor(x, lags; kwargs...))
# non-Missing types supplied with missing strategy directly call original function
#
# missing types without MissingStrategy call the PassMissing() variant
@traitfn function autocor(x::::IsEltypeSuperOfMissing; kwargs...)
    autocor(x, PassMissing(), kwargs...)
end
@traitfn function autocor(x::::IsEltypeSuperOfMissing, lags::AbstractVector{<:Integer};
    kwargs...)
    autocor(x, lags, PassMissing(); kwargs...)
end
# if lags is not provided, call default_autolags
@traitfn function autocor(x::::IsEltypeSuperOfMissing, ms::MissingStrategy; kwargs...)
    autocor(x, StatsBase.default_autolags(size(x,1)), ms; kwargs...)
end
# Passmissing returs missing on any missing entry or converts argument types
@traitfn function autocor(x::::IsEltypeSuperOfMissing, lags::AbstractVector{<:Integer},
    ms::PassMissing; kwargs...)
    any(ismissing.(x)) && return(missing)
    xnm = convert.(nonmissingtype(eltype(x)),x)
    SimpleTraits.istrait(IsEltypeSuperOfMissing(typeof(x1nm))) && error(
        "could not convert to nonmissing")
    autocor(xnm, lags; kwargs...)
end
# SkipMissing replaces missings by zero after demeaning.
#   This underestimates both variance and covariances with varying effect on correlation
# ExactMissing devides by a smaller number of terms
@traitfn function autocor(x::::IsEltypeSuperOfMissing, lags::AbstractVector{<:Integer},
    ms::HandleMissingStrategy; demean::Bool=true, kwargs...)
    z::Vector{Union{Missing,eltype(x)}} = demean ? x .- mean(skipmissing(x)) : x
    # replace missing by zero: new type will not match signature of current function 
    zpure = coalesce.(z, zero(z))::Vector{nonmissingtype(eltype(x))}
    acf = autocor(zpure,lags;demean=false,kwargs...)
    ms !== ExactMissing() && return(acf)
    # correct for sum has been devided by a larger number of terms
    # (including terms of missing/0) 
    lx = length(x)
    #zcorr = nterm_forlag(x,0)/lx
    missinginpair(x,y) = ismissing(x) || ismissing(y)
    zcorr_can = lx - count_forlag(missinginpair,x,0)#nterm_forlag(x,0)
    for (i,k) in enumerate(lags)
        #autocor code devides by lx instead of (lx-k)
        #https://github.com/JuliaStats/StatsBase.jl/issues/273#issuecomment-307560660
        # this cancels with lx of zcorr
        #acf[i] *= (lx - k)/nterm_forlag(x,k) * zcorr
        acf[i] *= zcorr_can/(lx - count_forlag(missinginpair,x,k)) 
    end
    acf
end

"""
    autocor_effective(x, ms::MissingStrategy=PassMissing())
    autocor_effective(x, acf)

Estimate the effective autocorrelation function for series x.

# Arguments
- `x`: An iterator of a series of observations
- `ms`: `MissingStrategy` passed to [`autocor`](@ref)
- `acf`: AutocorrelationFunction starting from lag 0

# Notes
- The effect autocorrelation function  
  are the first coefficients of the autocorrelation function up to 
  before the first negative coefficient. 
- According to Zieba 2011 using this effective version rather the full version
  when estimating the autocorrelationfunction from the data
  yields better result for the standard error of the mean ([`sem_cor`](@ref)).
- Optional argument `acf` allows the caller to provide a precomputed estimate
  of autocorrelation function (see [`autocor`](@ref)).
"""
function autocor_effective(x, ms::MissingStrategy=PassMissing()) 
    autocor_effective(x, autocor(x, ms))
end,
function autocor_effective(x, acf::AbstractVector)
    #maybe implement a more efficient version that computes only the
    # first lags and further lags if not found negative correlation
    i = findfirst(x -> x <= 0.0, acf)
    isnothing(i) && return(acf)
    acf[1:(i-1)]
end


@doc raw"""
    sem_cor(x, ms::MissingStrategy=PassMissing())
    sem_cor(x, acf::AbstractVector, ms::MissingStrategy=PassMissing())

Estimate the standard error of the mean of an autocorrelated series:
``Var(\bar{x}) = {Var(x) \over n_{eff}}``.    

# Arguments
- `x`: An iterator of a series of observations
- `acf`: AutocorrelationFunction starting from lag 0. 
- `ms`: `MissingStrategy` passed to [`effective_n_cor`](@ref).
  Value of `SkipMissing()` speeds up computation compared to `ExactMissing()`,
  but leads to a negatively biased result with absolute value of the bias 
  increasing with the number of missings.

# Optional Arguments
- `neff`: may provide a precomputed number of observations for efficiency.
"""
function sem_cor(x, ms::MissingStrategy=PassMissing(); kwargs...) 
    sx = isa(ms, HandleMissingStrategy) ? std(skipmissing(x)) : std(x)::eltype(x)
    ea = early_var_return(x, abs2(sx)); isnothing(ea) || return(something(ea))
    #!(Missing <: eltype(x)) && return(sem_cor(x, autocor_effective(x)))
    acfe = autocor_effective(x, ms; kwargs...)
    sem_cor(x, acfe, ms)
end,
# function sem_cor(x, acfe, ms::MissingStrategy=PassMissing(); neff=nothing)
#     sx = isa(ms, HandleMissingStrategy) ? std(skipmissing(x)) : std(x)::eltype(x)
#     ea = early_var_return(x, abs2(sx)); isnothing(ea) || return(something(ea))
#     #length(x) <= 1 && return(sx)
#     if isnothing(neff); neff = effective_n_cor(x, acfe, ms); end
#     #x, acfe, ms, neff
#     σ2 = var_cor(x, acfe, ms; neff=neff)
#     √(σ2/neff)
# end
@traitfn function sem_cor(x::::!(IsEltypeSuperOfMissing), acfe, ::MissingStrategy; neff=nothing)
    ea = early_var_return(x, abs2(sx)); isnothing(ea) || return(something(ea))
    if isnothing(neff); neff = effective_n_cor(x, acfe, ms); end
    σ2 = var_cor(x, acfe, ms; neff=neff)
    √(σ2/neff)
end
@traitfn function sem_cor(x::::IsEltypeSuperOfMissing, acfe, ms::PassMissing; neff=nothing)
    any(ismissing.(x)) && return(missing)
    x1nm = convert.(nonmissingtype(eltype(x)),x)
    Missing <: typeof(x1nm) && error("could not convert to nonmissing type")
    sem_cor(x1nm, acfe, ms; neff=neff)
end

@doc raw"""
    var_cor(x, ms::MissingStrategy=PassMissing())
    var_cor(x, acf::AbstractVector, ms::MissingStrategy=PassMissing())

Estimate the variance for an autocorrelated series.

Zieba 2011 provide the following formula:
```math
Var(x) = \frac{n_{eff}}{n (n_{eff}-1)} \sum \left( x_i - \bar{x} \right)^2 
= {(n-1) n_{eff} \over n (n_{eff}-1)} Var_{uncor}(x)
```    

# Arguments
- `x`: An iterator of a series of observations
- `acf`: AutocorrelationFunction starting from lag 0. 
- `ms`: `MissingStrategy` passed to [`effective_n_cor`](@ref).
  Value of `SkipMissing()` speeds up computation compared to `ExactMissing()`,
  but leads to a negatively biased result with absolute value of the bias 
  increasing with the number of missings.

# Optional Arguments
- `neff`: may provide a precomputed number of observations for efficiency.
"""
function var_cor(x, ms::MissingStrategy=PassMissing(); neff=nothing) 
    varx = isa(ms, HandleMissingStrategy) ? var(skipmissing(x)) : var(x)::eltype(x)
    ea = early_var_return(x, varx); isnothing(ea) || return(something(ea))
    acf = autocor(x, ms)
    var_cor(x, autocor_effective(x, acf), ms)
end,
function var_cor(x, acfe, ms::MissingStrategy=PassMissing(); neff=nothing)
    varx = isa(ms, HandleMissingStrategy) ? var(skipmissing(x)) : var(x)::eltype(x)
    ea = early_var_return(x, varx); isnothing(ea) || return(something(ea))
    n = length(x)
    nmiss = count(ismissing.(x))
    nfin = n - nmiss
    if isnothing(neff); neff = effective_n_cor(x, acfe, ms); end
    σ2uncorr = var(skipmissing(x))
    # BLUE Var(x) for correlated: Zieba11 eq.(1) 
    σ2 = σ2uncorr*(nfin-1)*neff/(nfin*(neff-1))
end

function early_var_return(x, varx=var(x))
    ismissing(varx) && return(missing)
    !isfinite(varx) && return(varx)
    varx == zero(varx) && return(varx)
    nothing
end

@doc raw"""
    effective_n_cor(x, ms::MissingStrategy=PassMissing()) 
    effective_n_cor(x, acf::AbstractVector, ms::MissingStrategy=PassMissing())

Compute the number of effective observations for an autocorrelated series.

# Arguments
- `x`: An iterator of a series of observations.
- `ms`: `MissingStrategy`: If not given defaults to `PassMissing`. 
  Set to `ExactMissing()` to consciouly handle missing value in `x`.
- `acf`: AutocorrelationFunction starting from lag 0. 
   If not given, defaults to `autocor(x, ms)` 

The formula in Zieba has been extended for missing values:
```math
n_{eff} = \frac{n_F}{1+{2 \over n_F} \sum_{k=1}^{min(n-1,n_k)} (n-k-m_k) \rho_k}
```
where ``n`` is the number of total records, ``n_F`` is the number of 
finite records, ``n_k`` is the nummber of components in the 
used autocorrelation function (``n-1`` if not estimated from the data)
,``\rho_k`` is the correlation, and 
``m_k`` is the number of pairs that contain a missing value for lag ``k``.

# Details
Missing values are not handled by default, i.e. the number of effective
observations is missing if ther any missings in `x`. 
The recommended way is using `ExactMissing()`. 
Alternatively, se to  `SkipMissing()` to speed up computation 
(by internally omitting [`count_forlags`](@ref) missing pairs) 
at the cost of a positively biased
result with increasing bias with the number of missings. 
The latter leads to a subsequent underestimated uncertainty of the sum or the mean.

# Examples
```jldoctest; output = false, setup = :(using LogNormals)
using Distributions, DistributionVectors, Missings, MissingStrategies, LinearAlgebra
acf0 = [1,0.4,0.1]
Sigma = cormatrix_for_acf(100, acf0);
# 100 random variables each Normal(1,1)
dmn = MvNormal(ones(100), Symmetric(Sigma));
x = allowmissing(rand(dmn));    
x[11:20] .= missing
neff = effective_n_cor(x, acf0, ExactMissing())
neff < 90
neff_biased = effective_n_cor(x, acf0, SkipMissing())
neff_biased > neff
# output
true
```
"""
function effective_n_cor(x)
    effective_n_cor(x, PassMissing())
end,
function effective_n_cor(x, ms::MissingStrategy)
    acf = autocor(x,ms)
    ismissing(acf) && return(missing)
    effective_n_cor(x, acf, ms)
end,
function effective_n_cor(x::AbstractVector, ms::MissingStrategy) 
    # need to repeat for ms,x for x::AbstractVector in order to solve method ambiguities
    acf = autocor(x,ms)
    ismissing(acf) && return(missing)
    effective_n_cor(x, acf, ms)
end
@traitfn function effective_n_cor(x::::!(IsEltypeSuperOfMissing), acf::AbstractVector) 
    effective_n_cor_neglectmissing(x, acf)
end
@traitfn function effective_n_cor(x::::IsEltypeSuperOfMissing, acf::AbstractVector) 
    effective_n_cor(x, acf, PassMissing())
end
@traitfn function effective_n_cor(x::::!(IsEltypeSuperOfMissing), acf::AbstractVector, 
    ::MissingStrategy)
    # for any MissingStrategy, if x is not of missing type call original
    effective_n_cor_neglectmissing(x, acf)  
end
@traitfn function effective_n_cor(x::::IsEltypeSuperOfMissing, acf::AbstractVector, 
    ::SkipMissing)
    # also for SkipMissing call original with (with x of full length)
    # which differs from effective_n_cor(skipmissing(x), acf)
    effective_n_cor_neglectmissing(x, acf)  
end
@traitfn function effective_n_cor(x::::IsEltypeSuperOfMissing, acf::AbstractVector, 
    ::PassMissing)
    # return missing if there are any missings, otherwise call original
    any(ismissing.(x)) && return missing
    effective_n_cor_neglectmissing(x, acf)  
end
@traitfn function effective_n_cor(x::::IsEltypeSuperOfMissing, acf::AbstractVector, 
    ::ExactMissing)
    # Zieba 2001 eq.(3)
    n = length(x)
    k = Base.OneTo(min(n,length(acf))-1) # acf starts with lag 0
    # see derivation in sem_cor.md
    # count the number of pairs with missings for each lag
    mk = count_forlags((x_i,x_iplusk)->ismissing(x_i) || ismissing(x_iplusk), x, k)
    nf = n - count(ismissing.(x))
    neff = nf/(1 + 2/nf*sum((n .- k .-mk) .* acf[k.+1]))  
end
function effective_n_cor_neglectmissing(x, acf::AbstractVector) 
    @show typeof(x)
    #Missing <: eltype(x) && error("assumes x without missing. Use effective_ncor(..., ExcactMissing()")
    n = length(x)
    k = Base.OneTo(min(n,length(acf))-1) # acf starts with lag 0
    neff = n/(1 + 2/n*sum((n .- k) .* acf[k.+1]))  
end




