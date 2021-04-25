# =================================================================================================
#     gappa heat-tree
# =================================================================================================

# Rule to create a heat tree visualization for all samples combined
rule gappa_heat_tree_all:
    input:
        expand( "placed/{sample}.jplace", sample=samples.keys() )
    output:
        expand("heat-tree.{ext}", ext=config["params"]["gappa"]["heat-tree"]["formats"])
    params:
        extra=config["params"]["gappa"]["heat-tree"]["extra"],
    log:
        "logs/gappa/heat_tree_all.log"
    conda:
        "../envs/gappa.yaml"
    script:
        "../scripts/gappa-heat-tree.py"

# Rule to create individual heat tree visualizations per sample
rule gappa_heat_tree:
    input:
        "placed/{sample}.jplace"
    output:
        expand("heat-trees/{{sample}}.{ext}", ext=config["params"]["gappa"]["heat-tree"]["formats"])
    params:
        extra=config["params"]["gappa"]["heat-tree"]["extra"],
    log:
        "logs/gappa/heat_trees/{sample}.log"
    conda:
        "../envs/gappa.yaml"
    script:
        "../scripts/gappa-heat-tree.py"
