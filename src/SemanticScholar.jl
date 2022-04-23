module SemanticScholar

export SemanticScholarConnection

using DataStructures
using Dates
using HTTP: request as http_request
using URIs
using JSON3

struct SemanticScholarConnection
    requests_buffer::CircularBuffer{DateTime}

    function SemanticScholarConnection()
        buffer = CircularBuffer{DateTime}(100)

        return new(buffer)
    end
end

"""
Removes "expired" request times from the buffer.
"""
function _clean_buffer!(ssc::SemanticScholarConnection)
    # remove requests older than rate limit period (default 5 minutes)
    threshold = now() - Minute(5)
        
    while !isempty(ssc.requests_buffer)
        requested_time = first(ssc.requests_buffer)

        requested_time > threshold && break

        popfirst!(ssc.requests_buffer)
    end

    return ssc
end

function _request(ssc::SemanticScholarConnection, path, query="")
    _clean_buffer!(ssc)

    # wait a sufficient amount of time (this function is blocking, but it doesn't check)
    if isfull(ssc.requests_buffer)
        threshold = now() - Minute(5)
        sleep_time = max(zero(DateTime), first(ssc.requests_buffer) - threshold)

        sleep(sleep_time)
    end
    
    # make actual request
    url = URI(
        scheme="https", 
        host="api.semanticscholar.org", 
        path="/graph/v1/" * strip(path, ['/']),
        query=query,
    )
    push!(ssc.requests_buffer, now())
    
    try
        response = http_request("GET", url)

        return JSON3.read(String(response.body))
    catch ex
        msg = JSON3.read(String(ex.response.body)).error
        throw(ErrorException(msg))
    end
end

###############################################################################
# LOW-LEVEL API (direct calls to semantic scholar)
###############################################################################

"""
    paper_search(s2c, query; fields=["title"], limit=10, offset=0)

Make a paper search request to the S2 API (equivalent to "/paper/search" endpoint).
The `query` must be "plaintext" with no special search filters.
"""
function paper_search(
    ssc::SemanticScholarConnection, search_query; 
    fields=["title"],
    limit=10,
    offset=0
)

    limit + offset < 10_000 || throw(ArgumentError("The sum of offset and limit must be < 10000"))

    response = _request(ssc, "/paper/search", [
        "query" => search_query,
        "fields" => join(fields, ","),
        "offset" => offset,
        "limit" => limit,
    ])

    return response["data"]
end

"""
    paper_details(s2c, paper_id; fields)

Make a request for details about a paper to the S2 API (equivalent to "/paper/{paper_id}" endpoint).
"""
function paper_details(
    ssc::SemanticScholarConnection, paper_id;
    fields
)

    response = _request(ssc, "/paper/$(paper_id)", [
        "fields" => join(fields, ","),
    ])

    return response
end

"""
    paper_authors(s2c, paper_id; fields=[], offset=0, limit=500)

Make a paper authors request to the S2 API (equivalent to "/paper/{paper_id}/authors" endpoint).
"""
function paper_authors(
    ssc::SemanticScholarConnection, paper_id;
    fields=[],
    offset=0,
    limit=500,
)

    limit + offset < 10_000 || throw(ArgumentError("The sum of offset and limit must be < 10000"))

    response = _request(ssc, "/paper/$(paper_id)/authors", [
        "fields" => join(fields, ","),
        "offset" => offset,
        "limit" => limit,
    ])

    return response
end

"""
    paper_citations(s2c, paper_id; fields=[], offset=0, limit=500)

Make a paper citations request to the S2 API (equivalent to "/paper/{paper_id}/citations" endpoint).
"""
function paper_citations(
    ssc::SemanticScholarConnection, paper_id;
    fields=[],
    offset=0,
    limit=500,
)

    limit + offset < 10_000 || throw(ArgumentError("The sum of offset and limit must be < 10000"))

    response = _request(ssc, "/paper/$(paper_id)/citations", [
        "fields" => join(fields, ","),
        "offset" => offset,
        "limit" => limit,
    ])

    return response
end

"""
    paper_references(s2c, paper_id; fields=[], offset=0, limit=500)

Make a paper references request to the S2 API (equivalent to "/paper/{paper_id}/references" endpoint).
"""
function paper_references(
    ssc::SemanticScholarConnection, paper_id;
    fields=[],
    offset=0,
    limit=500,
)

    limit + offset < 10_000 || throw(ArgumentError("The sum of offset and limit must be < 10000"))

    response = _request(ssc, "/paper/$(paper_id)/references", [
        "fields" => join(fields, ","),
        "offset" => offset,
        "limit" => limit,
    ])

    return response
end

"""
    author_search(s2c, query; fields=["title"], limit=10, offset=0)

Make an author search request to the S2 API (equivalent to "/author/search" endpoint).
"""
function author_search(
    ssc::SemanticScholarConnection, search_query; 
    fields=["title"],
    limit=10,
    offset=0
)

    limit + offset < 10_000 || throw(ArgumentError("The sum of offset and limit must be < 10000"))

    response = _request(ssc, "/author/search", [
        "query" => search_query,
        "fields" => join(fields, ","),
        "offset" => offset,
        "limit" => limit,
    ])

    return response["data"]
end

"""
    author_details(s2c, author_id; fields)

Make a request for author details to the S2 API (equivalent to "/author/{author_id}" endpoint).
"""
function author_details(
    ssc::SemanticScholarConnection, author_id;
    fields
)

    response = _request(ssc, "/paper/$(author_id)", [
        "fields" => join(fields, ","),
    ])

    return response
end

"""
    author_papers(s2c, author_id; fields=[], offset=0, limit=500)

Make an author papers request to the S2 API (equivalent to "/author/{author_id}/papers" endpoint).
"""
function author_papers(
    ssc::SemanticScholarConnection, author_id;
    fields=[],
    offset=0,
    limit=500,
)

    limit + offset < 10_000 || throw(ArgumentError("The sum of offset and limit must be < 10000"))

    response = _request(ssc, "/paper/$(author_id)/papers", [
        "fields" => join(fields, ","),
        "offset" => offset,
        "limit" => limit,
    ])

    return response
end

###############################################################################
# HIGH-LEVEL API (calls to SS are hidden behind struct constructions, etc)
###############################################################################

struct Paper{ReferenceType, CitationType, AuthorType}
    id::String
    title::String
    year::Int
    references::Vector{ReferenceType}
    citations::Vector{CitationType}
    authors::Vector{AuthorType}
    fields::Vector{String}
    embedding::Vector{Float64}

    Paper(id, title, year, references, citations, authors, fields, embedding) =
        new{eltype(references), eltype(citations), eltype(authors)}(
            id, title, year, references, citations, authors, fields, embedding,
        )
end

struct Author{PaperType}
    id::String
    name::String
    aliases::Vector{String}
    papers::Vector{PaperType}
    citation_count::Int

    Author(id, name, aliases, papers, citation_count) = 
        new{eltype(papers)}(
            id, name, aliases, papers, citation_count,
        )
end

_compress_somethings(stream, key) =
    [thing[key] for thing in stream if thing[key] !== nothing]


"""
    search_papers(s2c, query; limit=100)

Search the S2 Academic Graph for papers matching the search `query`.

This is a *high-level* API function, so it returns an array of `Paper`s.
"""
function search_papers(
    ssc::SemanticScholarConnection, search_query;
    limit=100,
)

    papers = Paper[]

    paper_data = paper_search(ssc, search_query, limit=limit, fields=[
        "title",
        "year",
        "fieldsOfStudy",
    ])

    for paper_datum in paper_data
        details_data = paper_details(ssc, paper_datum.paperId, fields=[
            "references.paperId",
            "citations.paperId",
            "authors.authorId",
            "embedding",
        ])
        
        push!(papers, Paper(
            paper_datum.paperId,
            paper_datum.title,
            paper_datum.year,
            _compress_somethings(details_data.references, "paperId"),
            _compress_somethings(details_data.citations, "paperId"),
            _compress_somethings(details_data.authors, "authorId"),
            paper_datum.fieldsOfStudy !== nothing ? copy(paper_datum.fieldsOfStudy) : [],
            details_data.embedding.vector,
        ))
    end

    return papers
end

"""
    search_authors(s2c, query; limit=50)

Search the S2 Academic Graph for authors with names matching the search `query`.

This is a *high-level* API function, so it returns an array of `Author`s.
"""
function search_authors(
    ssc::SemanticScholarConnection, search_query;
    limit=50,
)

    authors = Author[]

    author_data = author_search(ssc, search_query, limit=limit, fields=[
        "name",
        "aliases",
        "papers.paperId",
        "citationCount",
    ])

    for author_datum in author_data
        push!(authors, Author(
            author_datum.authorId,
            author_datum.name,
            author_datum.aliases,
            _compress_somethings(author_datum.papers, "paperId"),
            author_datum.citationCount
        ))
    end

    return authors
end

end
