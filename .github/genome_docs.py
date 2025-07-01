#!/usr/bin/env python3
from collections import defaultdict
from pprint import pprint


class Genome:
    def __init__(self, genome, attributes):
        self.genome = genome
        self.attributes = attributes

    @property
    def is_reference(self):
        return all(
            k in self.attributes
            for k in [
                "bioc_annot",
                "bioc_txdb",
                "blacklist_index",
                "chrom_sizes",
                "chromosomes_dir",
                "effective_genome_size",
                "fasta",
                "gene_info",
                "genes_gtf",
                "meme_motifs",
                "reference_index",
                "species",
            ]
        )

    @property
    def is_spike(self):
        return all(
            k in self.attributes
            for k in ["species", "fasta", "reference_index", "blacklist_bed"]
        )

    @property
    def md(self):
        md = [f"- `{self.genome}`"]
        for key, value in self.attributes.items():
            md.append(f"  - {key}: `{value}`")
        return md


def parse_genome_config(file_path):
    genomes = defaultdict(dict)
    with open("conf/genomes.config", "r") as config_file:
        next(config_file)  # Skip the first line
        next(config_file)  # Skip the second line
        for line in config_file:
            line = line.strip()
            if line.startswith('"') or line.startswith("'") and line.endswith("{"):
                genome = line.strip(" {").strip('"').strip("'")
            elif "=" in line:
                if "//" in line:
                    line = line.split("//")[0]
                key, value = line.split("=")
                genomes[genome][key.strip()] = value.strip().strip('"').strip("'")
    return {
        genome: Genome(genome, attributes)
        for genome, attributes in genomes.items()
        if attributes
    }


def to_markdown(genomes):
    md = list()

    md += [
        "## Reference Genomes\n",
        "These genomes can be passed to the `--genome` parameter.\n",
    ]
    for gname, genome in genomes.items():
        if genome.is_reference:
            md += genome.md
    md += [
        "\n## Spike-in Genomes\n",
        "These genomes can be passed to the `--spike_genome` parameter.\n",
    ]
    for gname, genome in genomes.items():
        if genome.is_spike:
            md += genome.md
    return md


def main():
    genomes = parse_genome_config("conf/genomes.config")
    markdown = to_markdown(genomes)
    with open("docs/_genomes_head.md", "r") as header_file:
        head = header_file.readlines()
    with open("docs/guide/genomes.md", "w") as md_file:
        md_file.writelines(head)
        for line in markdown:
            md_file.write(line + "\n")


if __name__ == "__main__":
    main()
