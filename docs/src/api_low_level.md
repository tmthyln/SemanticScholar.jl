# Low-Level API (Direct Mapping to Web API)

Both the low- and high-level APIs start off with an instance of `SemanticScholarConnection`,
which handles managing the request rate.

```julia-repl
julia> using SemanticScholar

julia> s2c = SemanticScholarConnection()
SemanticScholarConnection(Dates.DateTime[])

```

This `s2c` struct is then passed to all of the functions to make requests to the Semantic Scholar API.

## Paper Related

```@docs
SemanticScholar.paper_search
SemanticScholar.paper_details
SemanticScholar.paper_authors
SemanticScholar.paper_citations
SemanticScholar.paper_references
```

## Author Related

```@docs
SemanticScholar.author_search
SemanticScholar.author_details
SemanticScholar.author_papers
```
