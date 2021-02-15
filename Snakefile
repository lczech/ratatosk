include: "rules/common.smk"

# =================================================================================================
#     Default "All" Target Rule
# =================================================================================================

# The rule that is executed by default. We include the result files of different important
# intermediate steps here as well, for example, the placement files, so that a nice
# arrow shows up in the DAG that reminds us that this is an important intermediate file.
rule all:
    input:
        expand( "placed/{sample}.jplace", sample=samples.keys() )

# The main `all` rule is local. It does not do anything anyway,
# except requesting the other rules to run.
localrules: all

# =================================================================================================
#     Rule Modules
# =================================================================================================

include: "rules/align-hmmer.smk"
include: "rules/place-epa-ng.smk"
