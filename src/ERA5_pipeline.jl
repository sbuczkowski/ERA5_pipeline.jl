module ERA5_pipeline

import CDSAPI, TOML

export retrieve

"""
    read_config(config_file::String)::Dict

Read in specified TOML configuration file and format config values in a returned dictionary
"""
function read_config(config_file :: String) :: Dict

    config = TOML.tryparsefile(config_file)

    # perform sanity checks on config as read
    haskey(config, "output") || error("""Config has no "output" stanza""" )
    haskey(config, "cds_global") || error("""Config has no "cds_global" stanza""")
    haskey(config["output"], "query_names") || error("""Config contains no output query_names""")
    haskey(config["cds_global"], "product_type") || error("""Config contains no cds_global "product_type" """)

    # check that query stanzas exist for each query_name requested
    foreach(x -> (haskey(config, "$x") || error("""Config has no query stanza "$x" """)), values(config["output"]["query_names"]))

    return config
end

"""
    build_cdsvars(config::Dict, query::String, year:Integer, month::Integer)

Build the CDSAPI dictionary to drive the required query to retrieve Copernicus data
"""
function build_cdsvars(config :: Dict, query :: String, year :: Integer, month :: Integer)

    cdsvars = Dict("format" => config["output"]["format"],
                   "product_type" => config["cds_global"]["product_type"],
                   "grid" => config["cds_global"]["grid"],
                   "time" => config["cds_global"]["times"],
                   "variable" => config["$query"]["vlist"],
                   "year" => year > 1980 & year < 2050 ? string(year) : error("Requested year out of range"),
                   "month" => month >= 1 & month <= 12 ? string(month, pad=2) : error("Requested month out of range"))

    if query == "lev"
        @info "Merging atmospheric levels into cdsvars"
        merge!(cdsvars, Dict("pressure_level" => config["lev"]["levels"]))
    end

    # build output file path: config["output"]["basepath"]/year/month/year-month_query.nc
    filename = string(year) * "-" * string(month,pad=2) * "_" * query * ".nc"
    outfilepath = joinpath(config["output"]["basepath"],string(year),filename)
    
    return cdsvars, outfilepath
end

"""
    retrieve_single(config::Dict, query::String, year::Integer, month::Integer)

Wrapper to build and execute a single CDSAPI retrieval query
"""
function retrieve_single(config::Dict, query::String, year::Integer, month::Integer)

    @info "Building and executing query for $query config stanza"
    cdsvars, outfilepath = build_cdsvars(config, query, year, month)

    CDSAPI.retrieve(config["$query"]["database"], cdsvars, outfilepath)

end

"""
    retrieve(config_file::String, year::Integer, month::Integer)

Wrapper to build and execute all CDSAPI retrieval queries defined in the specified configuration file
"""
function retrieve(config_file::String, year::Integer, month::Integer)
    
    config = read_config(config_file)
                            
    # config["output"]["query_names"] drives retrieval behavior
    foreach(x -> retrieve_single(config, x, year, month), values(config["output"]["query_names"]))
    
end


end # module ERA5_pipeline
