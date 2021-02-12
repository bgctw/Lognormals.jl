using Test, Distributions, LogNormals

@testset "lognormal" begin

@testset "LogNormal properties" begin
    @testset "σstar" begin
        d = LogNormal(1,2)    
        @test σstar(d) == exp(2)
    end;
end;

@testset "LogNormal fit to stats" begin
    @testset "fit moments" begin
        D = LogNormal(1,0.6)
        M = Moments(mean(D), var(D))
        Dfit = fit(LogNormal, M)
        @test D ≈ Dfit
        # handle not giving variance
        @test_throws Exception fit(LogNormal, Moments(3.2))
    end;
    @testset "fit two quantiles" begin
        qpl = @qp_m(3)
        qpu = @qp_u(5)
        d = fit(LogNormal, qpl, qpu);
        @test quantile.(d, [qpl.p, qpu.p]) ≈ [qpl.q, qpu.q]
        d = fit(LogNormal, qpu, qpl) # sort
        @test quantile.(d, [qpl.p, qpu.p]) ≈ [qpl.q, qpu.q]
    end;
    @testset "fit to quantilepoint and mean" begin
        d = LogNormal(1,1)
        m = log(mean(d))
        qp = @qp(0.95,quantile(d,0.95))
        dfit = LogNormals.fit_mean_quantile(LogNormal, mean(d), qp)
        @test dfit ≈ d
        dfit = fit(LogNormal, mean(d), qp, Val(:mean))
        @test dfit ≈ d
        # with lower quantile
        qp = @qp(0.05,quantile(d,0.05))
        dfit = LogNormals.fit_mean_quantile(LogNormal, mean(d), qp)
        @test dfit ≈ d
        # very close to mean can give very different results:
        qp = @qp(0.95,mean(d)-1e-4)
        dfit = LogNormals.fit_mean_quantile(LogNormal, mean(d), qp)
        @test mean(dfit) ≈ mean(d) && quantile(dfit, qp.p) ≈ qp.q
    end;
    @testset "fit to quantilepoint and mode" begin
        d = LogNormal(1,1)
        m = log(mode(d))
        qp = @qp(0.95,quantile(d,0.95))
        dfit = LogNormals.fit_mode_quantile(LogNormal, mode(d), qp)
        @test dfit ≈ d
        dfit = fit(LogNormal, mode(d), qp, Val(:mode))
        @test dfit ≈ d
        # with lower quantile
        qp = @qp(0.025,quantile(d,0.025))
        dfit = LogNormals.fit_mode_quantile(LogNormal, mode(d), qp)
        @test mode(dfit) ≈ mode(d) && quantile(dfit, qp.p) ≈ qp.q
    end;
    @testset "fit to quantilepoint and median" begin
        d = LogNormal(1,1)
        qp = @qp(0.95,quantile(d,0.95))
        dfit = fit(LogNormal, median(d), qp, Val(:median))
        @test dfit ≈ d
    end;
    @testset "Σstar" begin
        ss = Σstar(4.5)
        @test ss() == 4.5
    end;
    @testset "fit to mean and Σstar" begin
        d = LogNormal(1, log(1.2))
        dfit = fit(LogNormal, mean(d), Σstar(1.2))
        @test d == dfit
    end;
end;

end;