# =================================================================================================
#     Setup Dependencies
# =================================================================================================

include: "place-epa-ng-common.smk"

# =================================================================================================
#     Placement with epa-ng
# =================================================================================================

rule epa_ng_place:
    input:
        tree = config["data"]["reference-tree"],
        msa  = config["data"]["reference-alignment"],
        sequences = "chunkify/aligned/{sample}.fasta",

        # See the "simple" setup for an explanation of the model function that we use here.
        model = epa_ng_place_model( "input" )
    output:
        jplace = "chunkify/placed/{sample}.jplace"
    params:
        # Get the model if it is a string (and not a file).
        model = epa_ng_place_model( "params" ),

        # Get any extra params to use with epa-ng
        extra = config["params"]["epa-ng"]["extra"]
    log:
        "logs/place/{sample}.log"
    conda:
        "../envs/epa-ng.yaml"
    threads:
        config["params"]["epa-ng"]["threads"]
    script:
        "../scripts/epa-ng.py"
