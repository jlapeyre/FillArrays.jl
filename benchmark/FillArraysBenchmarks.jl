using BenchmarkTools
using FillArrays

using LinearAlgebra: triu, tril

BenchmarkTools.DEFAULT_PARAMETERS.overhead = BenchmarkTools.estimate_overhead()

# Define a parent BenchmarkGroup to contain our suite
const SUITE = BenchmarkGroup()

# Add some child groups to our benchmark suite.

###
### Eye
###

g = addgroup!(SUITE, "Eye", [])

eye1float = Eye{Float64}(1)
eye10float = Eye{Float64}(10)
eye1000float = Eye{Float64}(1000)
eye10int = Eye{Int}(10)
eye1000int = Eye{Int}(1000)

r1 = addgroup!(g, "reduction", [])
r2 = addgroup!(g, "properties", [])
r3 = addgroup!(g, "any/all", [])
r4 = addgroup!(g, "iterate", [])
r5 = addgroup!(g, "identities", [])

g1 = addgroup!(SUITE, "Zeros", [])

zeros10 = Zeros(10)
zeros10x10 = Zeros(10)

dimstring(a) = string("n=", size(a, 1))
funop(fun, op) = string(fun,"(", op, ", a)")

for a in (eye10float, eye1000float, eye10int, eye1000int)
    for fun in (sum,)
        r1[string(fun), string(eltype(a)), dimstring(a)] = @benchmarkable $fun($a)
    end
    for fun in (isone, iszero)
        r2[string(fun), string(eltype(a)), dimstring(a)] = @benchmarkable $fun($a)
    end
    for (fun, op) in ((any, isone), (all, isone))
        r3[funop(fun, op), string(eltype(a)), dimstring(a)] = @benchmarkable $fun($op, $a)
    end
    for fun in (collect,)
        r4[string(fun), string(eltype(a)), dimstring(a)] = @benchmarkable $fun($a)
    end
    for fun in (permutedims, triu, tril, inv)
        r5[string(fun), string(eltype(a)), dimstring(a)] = @benchmarkable $fun($a)
    end
end

for a in (eye1float,)
    for (fun, op) in ((any, isone), (all, isone))
        r3[funop(fun, op), string(eltype(a)), dimstring(a)] = @benchmarkable $fun($op, $a)
    end
end

###
### Zeros
###

# If a cache of tuned parameters already exists, use it, otherwise, tune and cache
# the benchmark parameters. Reusing cached parameters is faster and more reliable
# than re-tuning `SUITE` every time the file is included.
paramspath = joinpath(dirname(@__FILE__), "params.json")

if isfile(paramspath)
    loadparams!(SUITE, BenchmarkTools.load(paramspath)[1], :evals);
else
    tune!(SUITE)
    BenchmarkTools.save(paramspath, params(SUITE));
end

result = run(SUITE, verbose = true)
