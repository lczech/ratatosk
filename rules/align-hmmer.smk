# =================================================================================================
#     Alignment with hmmer
# =================================================================================================

rule hmmer_build:
    input:
        refmsa = config["data"]["reference-alignment"]
    output:
        hmmprofile = "hmm/profile.hmm"
    params:
        extra=config["params"]["hmmer"]["build-extra"],
        # TODO allow different types of states, also below at align step
        # states = ["dna"] if config["states"] == 0 else ["amino"]
        states = "dna"
    log:
        "logs/hmm/hmmer_build.log"
    threads:
        1
    conda:
        "../envs/hmmer.yaml"
    shell:
        "hmmbuild --cpu {threads} --{params.states} {params.extra} "
        "{output.hmmprofile} {input.refmsa} > {log} 2>&1"

rule hmmer_align:
    input:
        refmsa = config["data"]["reference-alignment"],
        hmmprofile = "hmm/profile.hmm",
        sample=get_sample_fasta
    output:
        sample="aligned/{sample}.fasta",
    params:
        extra=config["params"]["hmmer"]["align-extra"],
        refmsa=config["data"]["reference-alignment"],
        # states = ["dna"] if config["states"] == 0 else ["amino"]
        states = "dna"
    log:
        "logs/align/{sample}.log"
    conda:
        "../envs/hmmer.yaml"
    threads:
        config["params"]["hmmer"]["threads"]
    shell:
        "hmmalign --{params.states} --outformat afa -o {output.sample} "
        "--mapali {input.refmsa} {params.extra} {input.hmmprofile} {input.sample} > {log} 2>&1"
