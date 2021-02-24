var documenterSearchIndex = {"docs":
[{"location":"lognormalprops.html#Properties-of-the-LogNormal-distribution","page":"LogNormal properties","title":"Properties of the LogNormal distribution","text":"","category":"section"},{"location":"lognormalprops.html","page":"LogNormal properties","title":"LogNormal properties","text":"The LogNormal distribution can be characterized by the exponent of its parameters:","category":"page"},{"location":"lognormalprops.html","page":"LogNormal properties","title":"LogNormal properties","text":"exp(μ): the median\nexp(σ): the multiplicative standard deviation sigma^*.","category":"page"},{"location":"lognormalprops.html","page":"LogNormal properties","title":"LogNormal properties","text":"Function σstar returns the multiplicative standard deviation.","category":"page"},{"location":"lognormalprops.html","page":"LogNormal properties","title":"LogNormal properties","text":"A distribution can be specified by taking the log of median and sigma^*","category":"page"},{"location":"lognormalprops.html","page":"LogNormal properties","title":"LogNormal properties","text":"d = LogNormal(log(2), log(1.2))\nσstar(d) == 1.2","category":"page"},{"location":"lognormalprops.html","page":"LogNormal properties","title":"LogNormal properties","text":"Alternatively the distribution can be specified by its mean and sigma^* using type Σstar","category":"page"},{"location":"lognormalprops.html","page":"LogNormal properties","title":"LogNormal properties","text":"d = fit(LogNormal, 2, Σstar(1.2))\n(mean(d), σstar(d)) == (2, 1.2)","category":"page"},{"location":"lognormalprops.html#Detailed-API","page":"LogNormal properties","title":"Detailed API","text":"","category":"section"},{"location":"lognormalprops.html","page":"LogNormal properties","title":"LogNormal properties","text":"LogNormals.σstar(::LogNormal)","category":"page"},{"location":"lognormalprops.html#LogNormals.σstar-Tuple{LogNormal}","page":"LogNormal properties","title":"LogNormals.σstar","text":"σstar(d)\n\nGet the multiplicative standard deviation of LogNormal distribution d.\n\nArguments\n\nd: The type of distribution to fit\n\nExamples\n\nd = LogNormal(2,log(1.2))\nσstar(d) == 1.2\n\n\n\n\n\n","category":"method"},{"location":"lognormalprops.html","page":"LogNormal properties","title":"LogNormal properties","text":"StatsBase.fit(::Type{LogNormal}, ::Any, ::Σstar) ","category":"page"},{"location":"lognormalprops.html#StatsBase.fit-Tuple{Type{LogNormal},Any,Σstar}","page":"LogNormal properties","title":"StatsBase.fit","text":"fit(D, mean, σstar)\n\nFit a statistical distribution of type D to mean and multiplicative  standard deviation.\n\nArguments\n\nD: The type of distribution to fit\nmean: The moments of the distribution\nσstar::Σstar: The multiplicative standard deviation\n\nSee also σstar, Σstar. \n\nExamples\n\nd = fit(LogNormal, 2, Σstar(1.1));\n(mean(d), σstar(d)) == (2, 1.1)\n\n\n\n\n\n","category":"method"},{"location":"lognormalprops.html","page":"LogNormal properties","title":"LogNormal properties","text":"LogNormals.Σstar","category":"page"},{"location":"lognormalprops.html#LogNormals.Σstar","page":"LogNormal properties","title":"LogNormals.Σstar","text":"Σstar\n\nRepresent the multiplicative standard deviation of a LogNormal distribution.\n\nSupports dispatch of fit. Invoking the type as a function returns its single value.\n\nExamples\n\na = Σstar(4.2)\na() == 4.2\n\n\n\n\n\n","category":"type"},{"location":"distributionvector.html#Vector-of-random-variables,-i.e.-distributions","page":"Vector of random variables","title":"Vector of random variables, i.e. distributions","text":"","category":"section"},{"location":"distributionvector.html","page":"Vector of random variables","title":"Vector of random variables","text":"AbstractDistributionVector\nSimpleDistributionVector\nParamDistributionVector","category":"page"},{"location":"distributionvector.html#LogNormals.AbstractDistributionVector","page":"Vector of random variables","title":"LogNormals.AbstractDistributionVector","text":"AbstractDistributionVector{D <: Distribution}\n\nIs any type able represent a vector of distribution of the same type. This corresponds to a sequence of random variables, each characterized by the same type of distribution but with different parameters.  This allows aggregating functions to work, for example, computing the distribution of the sum of random variables by  sum(dv::AbstractDistributionVector).\n\nIt is parametrized by D <: Distribution defining the type of the distribution used for all the random variables.\n\nItems may be missing. Hence the element type of the iterator is  Union{Missing,D}.\n\nAbstractDistributionVector\n\nis iterable\nhas length and index access, i.e. dv[i]::D\naccess to entire parameter vectors: params(dv,Val(i))\nconversion of Tuple of Vectors: params(dv)\narray of random numbers: rand(n, dv): adding one  dimension that represents across random variables\n\nSpecific implementations,  need to implement at minimum methods length and getindex, and params.\n\nThere are two standard implementations:\n\nSimpleDistributionVector: fast indexing but slower params method \nParamDistributionVector: possible allocations in indexing but  faster params\n\nExamples\n\ndmn1 = MvNormal([0,0,0], 1)\ndmn2 = MvNormal([1,1,1], 2)\ndv = SimpleDistributionVector(dmn1, dmn2, missing, missing);\nsample = rand(dv,2);\n# 4 distr, each 2 samples of length 3\nsize(sample) == (3,2,4)\n\n\n\n\n\n","category":"type"},{"location":"distributionvector.html#LogNormals.SimpleDistributionVector","page":"Vector of random variables","title":"LogNormals.SimpleDistributionVector","text":"SimpleDistributionVector{D <: Distribution, V}\n\nIs an Vector-of-Distribution based implementation of  AbstractDistributionVector.\n\nVector of random var can be created by \n\nspecifying the distributions as arguments.\n\nd1 = LogNormal(log(110), 0.25)\nd2 = LogNormal(log(100), 0.15)\ndv = SimpleDistributionVector(d1, d2, missing);\nisequal(params(dv, Val(1)), [log(110), log(100), missing])\n\nproviding the Type of distribution and vectors of each parameter\n\nmu = [1.1,1.2,1.3]\nsigma = [1.01, 1.02, missing]\ndv = SimpleDistributionVector(LogNormal{eltype(mu)}, mu, sigma);\nisequal(params(dv, Val(1)), [1.1,1.2,missing])\n\nNote that if one of the parameters is missing, then the entire entry of the distribution is marked missing.\n\nSince Distributions are stored directly, indexing passes a reference. However, getting parameter vectors, required iterating all distributions,  and allocating a new vector.\n\n\n\n\n\n","category":"type"},{"location":"distributionvector.html#LogNormals.ParamDistributionVector","page":"Vector of random variables","title":"LogNormals.ParamDistributionVector","text":"ParamDistributionVector{D <: Distribution, V}\n\nIs an Tuple of Vectors based implementation of  AbstractDistributionVector.\n\nVector of random var can be created by \n\nspecifying the distributions as arguments with some overhead of converting the Distributions to vectors of each parameter\n\nd1 = LogNormal(log(110), 0.25)\nd2 = LogNormal(log(100), 0.15)\ndv = ParamDistributionVector(d1, d2, missing);\nisequal(params(dv, Val(1)), [log(110), log(100), missing])\n\nproviding the Type of distribution and vectors of each parameter\n\nmu = [1.1,1.2,1.3]\nsigma = [1.01, 1.02, missing]\ndv = ParamDistributionVector(LogNormal{eltype(mu)}, mu, sigma);\nismissing(dv[3])\nisequal(params(dv, Val(1)), [1.1,1.2,1.3]) # third still not missing here\n\nNote that if one of the parameters for entry i is missing, then dv[i] is missing.\n\nSince distributions are stored by parameter vectors, the acces to these vectors is just passing a reference. Indexing, will create Distribution types.\n\n\n\n\n\n","category":"type"},{"location":"distributionvector.html#Helpers","page":"Vector of random variables","title":"Helpers","text":"","category":"section"},{"location":"distributionvector.html","page":"Vector of random variables","title":"Vector of random variables","text":"The conversion between a missing-allowed vector of parameter tuples  to a tuple of vectors for each parameter  (as used by ParamDistributionVector) is provided in a type-stable manner by function vectuptotupvec.","category":"page"},{"location":"distributionvector.html","page":"Vector of random variables","title":"Vector of random variables","text":"vectuptotupvec","category":"page"},{"location":"distributionvector.html#LogNormals.vectuptotupvec","page":"Vector of random variables","title":"LogNormals.vectuptotupvec","text":"vectuptotupvec(vectup)\n\nTypesafe convert from Vector of Tuples to Tuple of Vectors.\n\nArguments\n\nvectup: A Vector of identical Tuples \n\nExamples\n\nvectup = [(1,1.01, \"string 1\"), (2,2.02, \"string 2\")] \nvectuptotupvec(vectup) == ([1, 2], [1.01, 2.02], [\"string 1\", \"string 2\"])\n\n\n\n\n\n","category":"function"},{"location":"sumlognormals.html#Sum-of-correlated-lognormal-random-variables","page":"Sum LogNormals","title":"Sum of correlated lognormal random variables","text":"","category":"section"},{"location":"sumlognormals.html","page":"Sum LogNormals","title":"Sum LogNormals","text":"Method sum for a DistributionVector{<:LogNormal} computes approximation of the distribution of the sum of the corresponding lognormal variables.","category":"page"},{"location":"sumlognormals.html","page":"Sum LogNormals","title":"Sum LogNormals","text":"See documentation of the sum function.","category":"page"},{"location":"sumlognormals.html","page":"Sum LogNormals","title":"Sum LogNormals","text":"In the following example the computed approximation is compared to a bootstrap sample of sums over three correlated random variables.","category":"page"},{"location":"sumlognormals.html","page":"Sum LogNormals","title":"Sum LogNormals","text":"using Distributions,LogNormals\nmu = log.([110,100,80])\nsigma = log.([1.2,1.5,1.1])\nacf1 = AutoCorrelationFunction([0.4,0.1])\ndv = SimpleDistributionVector(LogNormal{eltype(mu)}, mu, sigma);\ndsum = sum(dv, acf1)","category":"page"},{"location":"sumlognormals.html","page":"Sum LogNormals","title":"Sum LogNormals","text":"using StatsPlots,Plots,LinearAlgebra,Missings,Test\nfunction boot_dvsums_acf(dv, acf, nboot = 10_000)\n    μ, σ = params(dv)\n    Sigma = Diagonal(σ) * cormatrix_for_acf(length(dv), acf) * Diagonal(σ);\n    dn = MvNormal(disallowmissing(μ), Symmetric(Sigma));\n    x = rand(dn, nboot) .|> exp\n    sums = vec(sum(x, dims = 1))\nend\nsums = boot_dvsums_acf(dv, acf1); \n@test isapprox(dsum, fit(LogNormal, sums), rtol = 0.2) \np = plot(dsum, lab=\"computed\", xlabel=\"sum of 3 correlated lognormally distributed random variables\", ylabel=\"density\");\ndensity!(p, sums, lab=\"random sample\");\nvline!(p, [mean(dsum)], lab=\"mean computed\");\nvline!(p, [mean(sums)], lab=\"mean random\");\nvline!(p, quantile(dsum, [0.025, 0.975]), lab=\"cf computed\");\nvline!(p, quantile(sums, [0.025, 0.975]), lab=\"cf random\");\nplot(p)\nsavefig(\"sumlognormals.svg\"); nothing","category":"page"},{"location":"sumlognormals.html","page":"Sum LogNormals","title":"Sum LogNormals","text":"(Image: plot of sum of lognormals)","category":"page"},{"location":"fitstats.html#Distribution-Fitting-to-aggregate-statistics","page":"Fit to statistic","title":"Distribution Fitting to aggregate statistics","text":"","category":"section"},{"location":"fitstats.html","page":"Fit to statistic","title":"Fit to statistic","text":"This package provides method to fit a distribution to a given set of aggregate statistics.","category":"page"},{"location":"fitstats.html","page":"Fit to statistic","title":"Fit to statistic","text":"DocTestSetup = :(using Statistics,Distributions,LogNormals)","category":"page"},{"location":"fitstats.html","page":"Fit to statistic","title":"Fit to statistic","text":"# to specified moments\nd = fit(LogNormal, Moments(3.0,4.0))\n(mean(d), var(d)) .≈ (3.0, 4.0)\n\n# to mean and upper quantile point\nd = fit(LogNormal, 3, @qp_uu(8))\n(mean(d), quantile(d, 0.975)) .≈ (3.0, 8.0)\n\n# to mode and upper quantile point\nd = fit(LogNormal, 3, @qp_uu(8), Val(:mode))\n(mode(d), quantile(d, 0.975)) .≈ (3.0, 8.0)\n\n# to two quantiles, i.e confidence range\nd = fit(LogNormal, @qp_ll(1.0), @qp_uu(8))\n(quantile(d, 0.025), quantile(d, 0.975)) .≈ (1.0, 8.0)\n\n# approximate a different distribution by matching moments\ndn = Normal(3,2)\nd = fit(LogNormal, moments(dn))\n(mean(d), var(d)) .≈ (3.0, 4.0)","category":"page"},{"location":"fitstats.html#Fit-to-statistical-moments","page":"Fit to statistic","title":"Fit to statistical moments","text":"","category":"section"},{"location":"fitstats.html","page":"Fit to statistic","title":"Fit to statistic","text":"StatsBase.fit(::Type{D}, ::AbstractMoments) where {D<:Distribution}","category":"page"},{"location":"fitstats.html#StatsBase.fit-Union{Tuple{D}, Tuple{Type{D},AbstractMoments}} where D<:Distribution","page":"Fit to statistic","title":"StatsBase.fit","text":"fit(D, m)\n\nFit a statistical distribution of type D to given moments m.\n\nArguments\n\nD: The type of distribution to fit\nm: The moments of the distribution\n\nNotes\n\nThis can be used to approximate one distribution by another.\n\nSee also AbstractMoments, moments. \n\nExamples\n\nd = fit(LogNormal, Moments(3.2,4.6));\n(mean(d), var(d)) .≈ (3.2,4.6)\n\nd = fit(LogNormal, moments(Normal(3,1.2)));\n(mean(d), std(d)) .≈ (3,1.2)\n\nplot(d); lines(!Normal(3,1.2))\n\n\n\n\n\n","category":"method"},{"location":"fitstats.html","page":"Fit to statistic","title":"Fit to statistic","text":"moments(d::Distribution, ::Val{N} = Val(2)) where N ","category":"page"},{"location":"fitstats.html#LogNormals.moments-Union{Tuple{Distribution}, Tuple{N}, Tuple{Distribution,Val{N}}} where N","page":"Fit to statistic","title":"LogNormals.moments","text":"moments(D, ::Val{N} = Val(2))\n\nGet the first N moments of a distribution.\n\nSee also type AbstractMoments.\n\nExamples\n\nmoments(LogNormal(), Val(4))  # first four moments \nmoments(Normal())  # mean and variance\n\n\n\n\n\n","category":"method"},{"location":"fitstats.html","page":"Fit to statistic","title":"Fit to statistic","text":"The syntax Moments(mean,var) produces an object of type Moments <: AbstractMoments.","category":"page"},{"location":"fitstats.html","page":"Fit to statistic","title":"Fit to statistic","text":" AbstractMoments{N}","category":"page"},{"location":"fitstats.html#LogNormals.AbstractMoments","page":"Fit to statistic","title":"LogNormals.AbstractMoments","text":"AbstractMoments{N}\n\nA representation of statistical moments of a distribution\n\nThe following functions are supported\n\nn_moments(m): get the number of recorded moments\n\nThe following getters return a single moment or  throw an error if the moment has not been recorded\n\nmean(m): get the mean\nvar(m): get the variance\nskewness(m): get the variance\nkurtosis(m): get the variance\ngetindex(m,i): get the ith moment, i.e. indexing m[i]\n\nThe basic implementation Moments is immutable and convert(AbstractArray, m::Moments) returns an SArray{N,T}.\n\nExamples\n\nm = Moments(1,0.2);\nn_moments(m) == 2\nvar(m) == m[2]\n\nkurtosis(m) # throws error because its above 2nd moment\n\n\n\n\n\n","category":"type"},{"location":"fitstats.html#Fit-to-several-quantile-points","page":"Fit to statistic","title":"Fit to several quantile points","text":"","category":"section"},{"location":"fitstats.html","page":"Fit to statistic","title":"Fit to statistic","text":"StatsBase.fit(::Type{D}, ::QuantilePoint, ::QuantilePoint) where {D<:Distribution}","category":"page"},{"location":"fitstats.html#StatsBase.fit-Union{Tuple{D}, Tuple{Type{D},QuantilePoint,QuantilePoint}} where D<:Distribution","page":"Fit to statistic","title":"StatsBase.fit","text":"fit(D, lower, upper)\n\nFit a statistical distribution to a set of quantiles \n\nArguments\n\nD: The type of the distribution to fit\nlower:  lower QuantilePoint (p,q)\nupper:  upper QuantilePoint (p,q)\n\nNotes\n\nSeveral macros help to construct QuantilePoints\n\n@qp(p,q)    quantile at specified p: QuantilePoint(p, q)\n@qp_ll(q0_025)  quantile at very low p: QuantilePoint(0.025, q0_025) \n@qp_l(q0_05)    quantile at low p: QuantilePoint(0.05, q0_05) \n@qp_m(median)   quantile at median: QuantilePoint(0.5, median) \n@qp_u(q0_95)    quantile at high p: QuantilePoint(0.95, q0_95)  \n@qp_uu(q0_975)  quantile at very high p: QuantilePoint(0.975, q0_975) \n\nExamples\n\nd = fit(LogNormal, @qp_m(3), @qp_uu(5));\nquantile.(d, [0.5, 0.975]) ≈ [3,5]\n\n\n\n\n\n","category":"method"},{"location":"fitstats.html#Fit-to-mean,mode,median-and-a-quantile-point","page":"Fit to statistic","title":"Fit to mean,mode,median and a quantile point","text":"","category":"section"},{"location":"fitstats.html","page":"Fit to statistic","title":"Fit to statistic","text":"StatsBase.fit(::Type{D}, ::Any, ::QuantilePoint, ::Val{stats} = Val(:mean)) where {D<:Distribution, stats}","category":"page"},{"location":"fitstats.html#StatsBase.fit-Union{Tuple{stats}, Tuple{D}, Tuple{Type{D},Any,QuantilePoint}, Tuple{Type{D},Any,QuantilePoint,Val{stats}}} where stats where D<:Distribution","page":"Fit to statistic","title":"StatsBase.fit","text":"fit(D, val, qp, ::Val{stats} = Val(:mean))\n\nFit a statistical distribution to a quantile and given statistics\n\nArguments\n\nD: The type of distribution to fit\nval: The value of statistics\nqp: QuantilePoint(p,q)\nstats Which statistics to fit: defaults to Val(:mean).   Alternatives are: Val(:mode), Val(:median)\n\nExamples\n\nd = fit(LogNormal, 5, @qp_uu(14));\n(mean(d),quantile(d, 0.975)) .≈ (5,14)\n\nd = fit(LogNormal, 5, @qp_uu(14), Val(:mode));\n(mode(d),quantile(d, 0.975)) .≈ (5,14)\n\n\n\n\n\n","category":"method"},{"location":"fitstats.html#Implementing-support-for-another-distribution","page":"Fit to statistic","title":"Implementing support for another distribution","text":"","category":"section"},{"location":"fitstats.html","page":"Fit to statistic","title":"Fit to statistic","text":"In order to use the fitting framework for a distribution MyDist, one needs to implement the following four methods.","category":"page"},{"location":"fitstats.html","page":"Fit to statistic","title":"Fit to statistic","text":"StatsBase.fit(::Type{MyDist}, m::AbstractMoments)\n\nfit_mean_quantile(::Type{MyDist}, mean, qp::QuantilePoint)\n\nfit_mode_quantile(::Type{MyDist}, mode, qp::QuantilePoint)\n\nStatsBase.fit(::Type{MyDist}, lower::QuantilePoint, upper::QuantilePoint)","category":"page"},{"location":"fitstats.html","page":"Fit to statistic","title":"Fit to statistic","text":"The default method for fit with stats = :median already works based on the methods for two quantile points. If the general method on two quantile points cannot be specified, one can alternatively implement method:","category":"page"},{"location":"fitstats.html","page":"Fit to statistic","title":"Fit to statistic","text":"fit_median_quantile(::Type{MyDist}, median, qp::QuantilePoint)","category":"page"},{"location":"sumdist.html#Sum-of-correlated-random-variables","page":"Sum of random variables","title":"Sum of correlated random variables","text":"","category":"section"},{"location":"sumdist.html","page":"Sum of random variables","title":"Sum of random variables","text":"sum(::AbstractDistributionVector)","category":"page"},{"location":"sumdist.html#Base.sum-Tuple{AbstractDistributionVector}","page":"Sum of random variables","title":"Base.sum","text":"sum(dv::AbstractDistributionVector; <keyword arguments>)\nsum(dv::AbstractDistributionVector, corr; <keyword arguments>)\nsum(dv::AbstractDistributionVector, acf; <keyword arguments>)\n\nCompute the distribution of the sum of correlated random variables.\n\nArguments\n\ndv: The vector of distributions, see AbstractDistributionVector\n\nAn optional second arguments supports correlation between random variables.\n\ncorr::Symmetric: correlation matrix, or\nacf::AutoCorrelationFunction: coefficients of the   AutoCorrelationFunction\n\nKeyword arguments:\n\nskipmissings: Set to Val(true) to conciously care for missings in dv. \nisgapfilled::AbstractVector{Bool}: set to true for records that should  contribute to the sum but not to the decrease of relative uncertainty  with increasing number of records, e.g. for missing records that have  been estimated (gapfilled). \n\nThe sums of correlated variables require extra allocation and  support an additional keyword parameter  \n\nstorage: a mutable AbstractVector{eltype(D)} of length of dv  that provides storage space to avoid additional allocations.\n\n\n\n\n\n","category":"method"},{"location":"sumdist.html","page":"Sum of random variables","title":"Sum of random variables","text":"If correlations are only dependent on the distance of records, one can specify these correlation by a vector starting with distance, i.e. lag, 1.","category":"page"},{"location":"sumdist.html","page":"Sum of random variables","title":"Sum of random variables","text":"AutoCorrelationFunction","category":"page"},{"location":"sumdist.html#LogNormals.AutoCorrelationFunction","page":"Sum of random variables","title":"LogNormals.AutoCorrelationFunction","text":"AutoCorrelationFunction{T}\n\nA representation of the autocorrelation function.\n\nIt supports accessing the coeficients starting from lag 1 by\n\ncoef(acf::AutoCorrelationFunction): implements StatsBase.coef\n\nWrapping the vector of coefficients into its own type helps avoiding method ambiguities.\n\nExamples\n\nusing StatsBase: coef\nacf = AutoCorrelationFunction([0.4,0.1])\ncoef(acf) == [0.4,0.1]\n\n\n\n\n\n","category":"type"},{"location":"index.html#LogNormals.jl","page":"Home","title":"LogNormals.jl","text":"","category":"section"},{"location":"index.html#LogNormals-Package","page":"Home","title":"LogNormals Package","text":"","category":"section"},{"location":"index.html","page":"Home","title":"Home","text":" LogNormals","category":"page"},{"location":"index.html#LogNormals","page":"Home","title":"LogNormals","text":"Tools that help using the LogNormal distribution.\n\nFitting to various aggregate statistics\nSum of correlated lognormal random variables\n\n\n\n\n\n","category":"module"},{"location":"index.html","page":"Home","title":"Home","text":"Pages = [\"lognormalprops.md\", \"fitstats.md\", \"distributionvector.md\", \n\"sumdist.md\", \"sumlognormals.md\"]\nDepth = 2","category":"page"},{"location":"index.html","page":"Home","title":"Home","text":"see the github repository.","category":"page"}]
}
