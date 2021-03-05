"""
Tools that help using the LogNormal distribution.

- Fitting to various aggregate statistics
- Sum of correlated lognormal random variables
"""
module LogNormals

export AbstractMoments, Moments, n_moments, moments,
    QuantilePoint, Σstar, σstar, 
    fit_mean_quantile, fit_mode_quantile, fit_median_quantile,
    @qp, @qp_ll, @qp_l, @qp_m, @qp_u, @qp_uu, 
    @qs_cf90, @qs_cf95,
    AbstractDistributionVector, SimpleDistributionVector, ParamDistributionVector,
    AutoCorrelationFunction,
    sum_lognormals, 
    sum_normals,
    cormatrix_for_acf,
    vectuptotupvec,
    autocor_effective, effective_n_cor, count_forlags, sem_cor

import Random: rand, rand!
import Base: sum, size
import Statistics: mean
import StatsBase: coef, autocor

using StatsBase, Distributions, StaticArrays, LinearAlgebra, Missings
using BandedMatrices, MappedArrays, RecursiveArrayTools, FillArrays, OffsetArrays
using Random

# general fitting to statistics
include("fitstats.jl")

# lognormal fitting
include("lognormal.jl")

# normal fitting
include("normal.jl")

# logitnormal fitting
include("logitnormal.jl")

# SimpleDistributionVector type
include("distributionvector.jl")

# types and method docu for sum of distributions
include("sumdistributionvector.jl")

# sum of normal random variables
include("sumnormals.jl")

# sum of lognormal random variables
include("sumlognormals.jl")

# standard error of the mean of correlated normal variables
include("semcor.jl")
    
end # module
