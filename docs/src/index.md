# SemanticScholar.jl Documentation

Semantic Scholar is an academic paper repository, which provides a convenient API.
The default scholar is able to make about 100 requests/5 minutes.
The SemanticScholar.jl package wraps the API to make it easier to access from Julia.
There are 2 APIs that this package exposes (for accessing the academic graph, not the peer reviews):
- low-level API: basically direct Julia bindings to their web API
- high-level API: encapsulates more high-level logic into structs and functions that
  are not necessarily linked to their API structure
  (this can be slower, depending on your specific needs; more data tends to be asked for in this API)


Suggestions or contributions welcome!

## Getting Started

You can install this package using Julia's default package manager:
```julia-repl
(env) pkg> add SemanticScholar
```
or
```julia-repl
julia> using Pkg

julia> Pkg.add("SemanticScholar)
```
