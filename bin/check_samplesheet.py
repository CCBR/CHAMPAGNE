#!/usr/bin/env python3

"""
adapted from: https://github.com/nf-core/chipseq/blob/51eba00b32885c4d0bec60db3cb0a45eb61e34c5/bin/check_samplesheet.py
"""
import collections
import os
import errno
import argparse
import operator
import pprint


def parse_args(args=None):
    Description = "Reformat nf-core/chipseq samplesheet file and check its contents."
    Epilog = "Example usage: python check_samplesheet.py <FILE_IN> <FILE_OUT>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("FILE_IN", help="Input samplesheet file.")
    parser.add_argument("FILE_OUT", help="Output file.")
    return parser.parse_args(args)


def make_dir(path):
    if len(path) > 0:
        try:
            os.makedirs(path)
        except OSError as exception:
            if exception.errno != errno.EEXIST:
                raise exception


def print_error(error, context="Line", context_str=""):
    error_str = f"ERROR: Please check samplesheet ->"
    if context != "" and context_str != "":
        error_str = "ERROR: Please check samplesheet -> {}\n{}: '{}'".format(
            error, context.strip(), context_str.strip()
        )
    raise ValueError(error_str)


def check_samplesheet(file_in, file_out):
    """
    This function checks that the samplesheet follows the following structure:
    sample,rep,fastq_1,fastq_2,antibody,control
    SPT5_T0_REP1,1,SRR1822153_1.fastq.gz,SRR1822153_2.fastq.gz,SPT5,SPT5_INPUT_REP1
    SPT5_T0_REP2,2,SRR1822154_1.fastq.gz,SRR1822154_2.fastq.gz,SPT5,SPT5_INPUT_REP2
    SPT5_INPUT_REP1,1,SRR5204809_Spt5-ChIP_Input1_SacCer_ChIP-Seq_ss100k_R1.fastq.gz,SRR5204809_Spt5-ChIP_Input1_SacCer_ChIP-Seq_ss100k_R2.fastq.gz,,
    SPT5_INPUT_REP2,2,SRR5204810_Spt5-ChIP_Input2_SacCer_ChIP-Seq_ss100k_R1.fastq.gz,SRR5204810_Spt5-ChIP_Input2_SacCer_ChIP-Seq_ss100k_R2.fastq.gz,,
    For an example see:
    https://raw.githubusercontent.com/nf-core/test-datasets/chipseq/samplesheet/v2.0/samplesheet_test.csv
    """

    sample_mapping_dict = {}
    input_dict = collections.defaultdict(list)
    with open(file_in, "r", encoding="utf-8-sig") as fin:
        ## Check header
        MIN_COLS = 2
        HEADER_MIN = ["sample", "rep", "fastq_1", "fastq_2", "antibody", "control"]
        header = [x.strip('"') for x in fin.readline().strip().split(",")]

        header_int = set(HEADER_MIN).intersection(set(header))
        if header_int != set(HEADER_MIN):
            print_error(
                f"{','.join(header)} doesn't contain required elements from {','.join(HEADER)}",
                context="Header",
            )

        ## Check sample entries
        for line in fin:
            lspl = [x.strip().strip('"') for x in line.strip().split(",")]

            # Check valid number of columns per row
            if len(lspl) != len(header):
                print_error(
                    f"Invalid number of columns (header length = {len(header)})!",
                    "Line",
                    line,
                )
            num_cols = len([x for x in lspl if x])
            if num_cols < MIN_COLS:
                print_error(
                    "Invalid number of populated columns (minimum = {})!".format(
                        MIN_COLS
                    ),
                    "Line",
                    line,
                )

            line_dict = {key: val for key, val in zip(header, lspl)}
            ## Check sample name entries
            (
                sample_basename,
                rep,
                fastq_1,
                fastq_2,
                antibody,
                control,
            ) = operator.itemgetter(*HEADER_MIN)(line_dict)
            print("lspl")
            pprint.pprint(lspl)
            sample = f"{sample_basename}_{rep}" if rep else sample_basename
            if sample.find(" ") != -1:
                print(
                    f"WARNING: Spaces have been replaced by underscores for sample: {sample}"
                )
                sample = sample.replace(" ", "_")
            if not sample:
                print_error("Sample entry has not been specified!", "Line", line)

            ## Check FastQ file extension
            for fastq in [fastq_1, fastq_2]:
                if fastq:
                    if fastq.find(" ") != -1:
                        print_error("FastQ file contains spaces!", "Line", line)
                    if not fastq.endswith(".fastq.gz") and not fastq.endswith(".fq.gz"):
                        print_error(
                            "FastQ file does not have extension '.fastq.gz' or '.fq.gz'!",
                            "Line",
                            line,
                        )

            ## Check antibody and control columns have valid values
            if antibody:
                if antibody.find(" ") != -1:
                    print(
                        f"WARNING: Spaces have been replaced by underscores for antibody: {antibody}"
                    )
                    antibody = antibody.replace(" ", "_")
                if not control:
                    print_error(
                        "Both antibody and control columns must be specified for non-control samples!",
                        "Line",
                        line,
                    )
            if control:
                if control.find(" ") != -1:
                    print(
                        f"WARNING: Spaces have been replaced by underscores for control: {control}"
                    )
                    control = control.replace(" ", "_")
                if not antibody:
                    print_error(
                        "Both antibody and control columns must be specified for non-control samples!",
                        "Line",
                        line,
                    )
            is_control_input = not antibody and not control

            ## Auto-detect paired-end/single-end
            if not sample or not fastq_1:
                print_error("Invalid combination of columns provided!", "Line", line)
            is_single = str(int(bool(fastq_1 and not fastq_2)))
            # prepare sample info
            sample_info = [
                sample,
                sample_basename,
                rep,
                is_single,
                fastq_1,
                fastq_2,
                antibody,
                control,
            ]
            print("sample_info")
            pprint.pprint(sample_info)

            ## Create sample mapping dictionary = {sample: [[ single_end, fastq_1, fastq_2, antibody, control ]]}
            if sample not in sample_mapping_dict.keys():
                sample_mapping_dict[sample] = [sample_info]
            else:
                print(f"{sample} in keys")
                if sample_info in sample_mapping_dict[sample]:
                    print_error("Samplesheet contains duplicate rows!", "Line", line)
                else:
                    sample_mapping_dict[sample].append(sample_info)
            if is_control_input:
                input_dict[sample_basename].append(sample_info)

    ## Write validated samplesheet with appropriate columns
    if len(sample_mapping_dict) > 0:
        out_dir = os.path.dirname(file_out)
        make_dir(out_dir)
        with open(file_out, "w") as fout:
            fout.write(
                ",".join(
                    [
                        "sample",
                        "sample_basename",
                        "rep",
                        "single_end",
                        "fastq_1",
                        "fastq_2",
                        "antibody",
                        "control",
                    ]
                )
                + "\n"
            )
            for sample in sorted(sample_mapping_dict.keys()):
                ## Check that multiple runs of the same sample are of the same datatype i.e. single-end / paired-end
                if not all(
                    x[0] == sample_mapping_dict[sample][0][0]
                    for x in sample_mapping_dict[sample]
                ):
                    print_error(
                        f"Multiple runs of a sample must be of the same datatype i.e. single-end or paired-end!",
                        "Sample",
                        sample,
                    )

                # check that the control/input exists
                for idx, val in enumerate(sample_mapping_dict[sample]):
                    control = val[-1]
                    if control and control not in input_dict.keys():
                        print_error(
                            "Control identifier has to match a provided sample identifier!",
                            "Control",
                            control,
                        )
                    fout.write(",".join(val) + "\n")
    else:
        print_error(f"No entries to process!", "Samplesheet: {file_in}")


def main(args=None):
    args = parse_args(args)
    check_samplesheet(args.FILE_IN, args.FILE_OUT)


if __name__ == "__main__":
    main()
