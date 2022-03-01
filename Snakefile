include: "rules/common.smk"

# =================================================================================================
#     Default "All" Target Rule
# =================================================================================================

# The rule that is executed by default. We include the result files of different important
# intermediate steps here as well, for example, the placement files, so that a nice
# arrow shows up in the DAG that reminds us that this is an important intermediate file.
rule all:
    input:
        expand("{outdir}/placed/{sample}.jplace",
            outdir=outdir,
            sample=sample_names
        ),
        expand("{outdir}/heat-tree.{ext}",
            outdir=outdir,
            ext=config["params"]["gappa"]["heat-tree"]["formats"]
        ),
        expand("{outdir}/heat-trees/{sample}.{ext}",
            outdir=outdir,
            sample=sample_names,
            ext=config["params"]["gappa"]["heat-tree"]["formats"]
        ) if config["params"]["gappa"]["heat-tree"]["sample-trees"] else [],
        expand("{outdir}/diversity/guppy/{sample}.csv",
            outdir=outdir,
            sample=sample_names
        )
# The main `all` rule is local. It does not do anything anyway,
# except requesting the other rules to run.
localrules: all

# =================================================================================================
#     Rule Modules
# =================================================================================================

# Based on the config file, we include certain rule files, for individual tools,
# and for the overall workflow (simple placement, or with chunkify).
if config["settings"]["use-chunkify"]:
    include: "rules/chunkify.smk"
    run_mode = "chunked"
else:
    run_mode = "simple"

# Make sure that the config fits our expectations.
# This might already be checked by the scheme anyway, but let's be safe.
if config["settings"]["alignment-tool"] not in [ "hmmer" ]:
    raise Exception("Unknown alignment-tool: " + config["settings"]["alignment-tool"])
if config["settings"]["placement-tool"] not in [ "epa-ng" ]:
    raise Exception("Unknown placement-tool: " + config["settings"]["placement-tool"])

# Now use the tool choice to load the correct rules.
include: "rules/align-" + config["settings"]["alignment-tool"] + "-" + run_mode + ".smk"
include: "rules/place-" + config["settings"]["placement-tool"] + "-" + run_mode + ".smk"

# Include additional rules.
include: "rules/gappa-heat-tree.smk"
include: "rules/diversity.smk"
