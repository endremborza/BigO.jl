const DEFAULT_ETA = 1e-3
const DEFAULT_STEPS = 3e3

abstract type Rescaler end

struct OrderGuess
    name::String
    testloss::Real
    trainloss::Real
    x::Array
    y::Array
    preds::Array
end

struct OrderEstimator
    name::String
    initparams::Array{Float64, 1}
    funform::Base.Callable
    scaler::Base.Callable
end

function OrderEstimator(name::String, initparams::Array{Float64, 1}, funform::Base.Callable)
    OrderEstimator(name, initparams, funform, PosScaler)
end

function getscale(a::Array)
    m = mean(a)
    s = std(a) |> (x -> x > 0 ? x : 1)
    return [m, s, minimum((a .- m) ./ s) - 1]
end

struct PosScaler <: Rescaler
    m::Real
    s::Real
    m2::Real

    PosScaler(a::Array) = new(getscale(a)...)
end

struct LogScaler <: Rescaler
    m::Real
    s::Real
    m2::Real

    LogScaler(a::Array) = new(getscale(log.(a))...)
end


transform(scaler::PosScaler, a::Array) = (a .- scaler.m) ./ scaler.s .- scaler.m2
function transform(scaler::LogScaler, a::Array)
    (log.(a) .- scaler.m) ./ scaler.s .- scaler.m2
end

invert(scaler::PosScaler, a::Array) = (a .+ scaler.m2) * scaler.s .+ scaler.m
invert(scaler::LogScaler, a::Array) = exp.((a .+ scaler.m2) * scaler.s .+ scaler.m)

function orders()
    return [
    OrderEstimator(
        "O(1)",
        [1.0],
        c -> (x -> c)
        ),
    OrderEstimator(
        "O(log n)",
        [0.0, 1.0, 2.0],
        (c, b, l) -> (x -> max(0.0, c) + max(1e-2, b) * log(max(1.01, l), x))
        ),
    OrderEstimator(
        "O(n)",
        [0.0, 1.0],
        (c, b) -> (x -> max(0.0,c) + max(0.001, b) * x)
        ),
    OrderEstimator(
        "O(n log n)",
        [0.0, 0.0, 1.0, 2.0],
        (c, b1, b2, l) -> (x -> max(0.0, c) + max(0, b1) * x + max(0.001, b2) * x * log(max(1.01, l), x))
        ),
    OrderEstimator(
        "O(n^p)",
        [0.0, 0.0, 1.0, 2.0],
        (c, b1, b2, p) -> (x -> max(0.0, c) + max(0, b1) * x + max(0.001, b2) * x ^ max(1.01, p))
        ),
    OrderEstimator(
        "O(k^n)",
        [0.0, 0.0, 1.0, 2.0],
        (c, b1, b2, k) -> (x -> max(0.0, c) + max(0, b1) * x + max(0.001, b2) * max(1.001, k) ^ x),
        LogScaler
        ),
    ]
end

function plot(guess::OrderGuess)
    plot(
        guess.x,
        hcat(guess.preds, guess.y),
        labels=["preds" "test"],
        legend=:topleft,
        title=guess.name
    )
end


function _optimize!(loss, parameters, eta, steps=1e5, breaklimit=1e-15)
    for _ in 1:steps
        l = loss(parameters...)
        l < breaklimit && break
        g = gradient(loss, parameters...) ./ l
        parameters .= parameters .- (g .* eta ./ sum(abs.(g)))
    end
end


function fit(order::OrderEstimator, x, y, eta=1e-3, steps=5e4)::Base.Callable
    scaler = order.scaler(y)

    prepped_y = transform(scaler, y)
    ps = order.initparams |> copy

    predscaler = order.scaler(order.funform(ps...).(x))

    model(ps) = x -> transform(predscaler, order.funform(ps...).(x))
    loss(ps...) = sum((model(ps)(x) .- prepped_y) .^ 2)

    ps[1] += mean(prepped_y .- model(ps)(x))
    _optimize!(loss, ps, eta, steps)

    return x -> invert(scaler, model(ps)(x))
end


function guessbigo(x, y, eta=DEFAULT_ETA, steps=DEFAULT_STEPS, trainrate=0.7)::Array{OrderGuess}

    te = (length(x) * trainrate) |> round |> Int
    train_x, train_y = (a -> a[1:te]).([x, y])
    test_x, test_y = (a -> a[te+1:end]).([x, y])

    recs = []
    for order in orders()
        estimator = fit(order, train_x, train_y, eta, steps)

        testerror = sum(abs.(estimator(test_x) .- test_y))
        trainerror = sum(abs.(estimator(train_x) .- train_y))
        push!(
            recs,
            OrderGuess(order.name, testerror, trainerror, x, y, estimator(x))
        )
    end
    return sort(recs, by=x-> x.testloss)
end
guessbigo(fun::Base.Callable, x=50:25:500, eta=DEFAULT_ETA, steps=DEFAULT_STEPS, trainrate=0.7) = guessbigo(x, fun.(x), eta, steps, trainrate)

best(guesses::Array{OrderGuess}) = sort(guesses, by=x-> x.testloss)[1].name

function bigos(report::RunReport, eta=DEFAULT_ETA, steps=DEFAULT_STEPS, trainrate=0.7)
    return Dict(
        [
            (
                report.names[i],
                guessbigo(
                    report.inputsizes,
                    report.times[:, i],
                    eta,
                    steps,
                    trainrate
                    ) |> best
            )
            for i in axes(report.names, 1)
        ]
    )
end
