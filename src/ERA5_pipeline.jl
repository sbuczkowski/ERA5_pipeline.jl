module ERA5_pipeline

using CDSAPI, TOML

#=
	cdsvars = Dict("format" => config["output"]["format"],
	"product_type" => config["cds_global"]["product_type"],
	"grid" => config["cds_global"]["grid"],
	"time" => config["cds_global"]["times"],
	"year" => "2023", "month" => "01",
	               "variable" => config["sfc"]["vlist"])

CDSAPI.retrieve(config["sfc"]["database"], cdsvars, "mytest.nc")
=#

function build_vars()
end

function read_config(config_file :: String) :: Dict

    config = TOML.tryparsefile(config_file)

end

function retrieve_single(dataset :: String, cdsvars :: Dict, outfilepath :: String)

    CDSAPI.retrieve(dataset, cdsvars, outfilepath)

end



end # module ERA5_pipeline
