module ERA5_pipeline

import CDSAPI, TOML

export retrieve_single


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

function build_cdsvars(config :: Dict, query :: String, year :: Int, month :: Int)

    cdsvars = Dict("format" => config["output"]["format"],
                   "product_type" => config["cds_global"]["product_type"],
                   "grid" => config["cds_global"]["grid"],
                   "time" => config["cds_global"]["times"],
                   "variable" => config["$query"]["vlist"],
                   "year" => year > 1980 & year < 2050 ? string(year) : error("Requested year out of range"),
                   "month" => month >= 1 & month <= 12 ? string(month, pad=2) : error("Requested month out of range"))

    if query == "lev"
        merge(cdsvars, Dict("levels" => config["lev"]["levels"]))
    end

    return cdsvars
end

function retrieve_single(dataset :: String, cdsvars :: Dict, outfilepath :: String)

    CDSAPI.retrieve(dataset, cdsvars, outfilepath)

end



end # module ERA5_pipeline
