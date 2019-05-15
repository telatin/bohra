# Bohra 

A pipeline for analysis of Illumina short reads for public health microbiology.

### Motivation

Bohra was inspired by Nullarbor (https://github.com/tseemann/nullarbor) to be used in public health microbiology labs for analysis of short reads from microbiological samples.  

### Limitations

Bohra is restricted to Illumina or Ion Torrent read sets. It has been built with the goal of being able to be run in HPC environments, although the configurations at this initial committ have not been included.

## Pipeline

Bohra can be run in three modes
1. SNPs and Phylogeny
* Clean reads
* Call variants
* Generate a phylogenetic tree

2. SNPs, Phylogeny, Typing, Annotation and Species Identification (DEFAULT)
* Clean reads
* Call variants
* Generate a phylogenetic tree
* Assemble
* Species identification
* MLST
* Resistome
* Annotate

3. SNPs, Phylogeny, PanGenome and  Typing and Species Identification
* Clean reads
* Call variants
* Generate a phylogenetic tree
* Assemble
* Species identification
* MLST
* Resistome
* Annotate
* Pan Genome

### Installation

At the moment bohra can only be installed via github - other options will follow

`pip3 install git+https://github.com/MDU-PHL/bohra`

### Initial run


```
usage: bohra.py run [-h] [--input_file INPUT_FILE] [--job_id JOB_ID]
                    [--reference REFERENCE] [--mask MASK]
                    [--pipeline {sa,s,a,all}]
                    [--assembler {shovill,skesa,spades}] [--cpus CPUS]
                    [--minaln MINALN] [--prefillpath PREFILLPATH] [--mdu MDU]
                    [--workdir WORKDIR] [--resources RESOURCES] [--force]
                    [--dryrun] [--gubbins]

optional arguments:
  -h, --help            show this help message and exit
  --input_file INPUT_FILE, -i INPUT_FILE
                        Input file = tab-delimited with 3 columns
                        <isolatename> <path_to_read1> <path_to_read2>
                        (default: )
  --job_id JOB_ID, -j JOB_ID
                        Job ID, will be the name of the output directory
                        (default: )
  --reference REFERENCE, -r REFERENCE
                        Path to reference (.gbk or .fa) (default: )
  --mask MASK, -m MASK  Path to mask file if used (.bed) (default: False)
  --pipeline {sa,s,a,all}, -p {sa,s,a,all}
                        The pipeline to run. SNPS ('s') will call SNPs and
                        generate phylogeny, ASSEMBLIES ('a') will generate
                        assemblies and perform mlst and species identification
                        using kraken2, SNPs and ASSEMBLIES ('sa' - default)
                        will perform SNPs and ASSEMBLIES. ALL ('all') will
                        perform SNPS, ASSEMBLIES and ROARY for pan-genome
                        analysis (default: sa)
  --assembler {shovill,skesa,spades}, -a {shovill,skesa,spades}
                        Assembler to use. (default: skesa)
  --cpus CPUS, -c CPUS  Number of CPU cores to run, will define how many rules
                        are run at a time (default: 36)
  --minaln MINALN, -ma MINALN
                        Minimum percent alignment (default: 0)
  --prefillpath PREFILLPATH, -pf PREFILLPATH
                        Path to existing assemblies - in the form
                        path_to_somewhere/isolatename/contigs.fa (default:
                        None)
  --mdu MDU             If running on MDU data (default: True)
  --workdir WORKDIR, -w WORKDIR
                        Working directory, default is current directory
                        (default: /home/khhor/dev/bohra)
  --resources RESOURCES, -s RESOURCES
                        Directory where templates are stored (default:
                        templates)
  --force, -f           Add if you would like to force a complete restart of
                        the pipeline. All previous logs will be lost.
                        (default: False)
  --dryrun, -n          If you would like to see a dry run of commands to be
                        executed. (default: False)
  --gubbins, -g         If you would like to run gubbins. NOT IN USE YET -
                        PLEASE DO NOT USE (default: False)
```

`python3 bohra.py run -r path_to_ref -i path_to_input -j job_id`

### Subsequent run

Once a run has been completed you can rerun bohra
1. Add or remove isolates
* Add - add a new tab-delimited line
* Prepend a `#` to the lines to remove

2. Change the reference 
* If changing the reference re-alignment and variant calling will be performed

3. Change the mask file

```
usage: bohra.py rerun [-h] [--reference REFERENCE] [--mask MASK] [--cpus CPUS]
                      [--workdir WORKDIR] [--resources RESOURCES] [--dryrun]
                      [--gubbins] [--keep]

optional arguments:
  -h, --help            show this help message and exit
  --reference REFERENCE, -r REFERENCE
                        Path to reference (.gbk or .fa) (default: )
  --mask MASK, -m MASK  Path to mask file if used (.bed) (default: )
  --cpus CPUS, -c CPUS  Number of CPU cores to run, will define how many rules
                        are run at a time (default: 36)
  --workdir WORKDIR, -w WORKDIR
                        Working directory, default is current directory
                        (default: /home/khhor/dev/bohra)
  --resources RESOURCES, -s RESOURCES
                        Directory where templates are stored (default:
                        templates)
  --dryrun, -n          If you would like to see a dry run of commands to be
                        executed. (default: False)
  --gubbins, -g         If you would like to run gubbins. NOT IN USE YET -
                        PLEASE DO NOT USE (default: False)
  --keep, -k            Keep report from previous run (default: False)
```
#### Rerun with different combination of isolates

`python3 bohra.py rerun`

#### Rerun with different reference/mask

`python3 bohra.py rerun -r pathtonewref -m pathtonewmask`

## Etymology

Bohra is an exinct tree dwelling kangaroo whose fossils have been found in the Nullarbor, before the Nullarbor was treeless. Since this pipeline implements [Snippy](https://github.com/tseemann/snippy), named for another famous Australian kangaroo ('Skippy') and designed based on [Nullarbor](https://github.com/tseemann/nullarbor) Bohra is an exceedingly appropriate name. 

## More to follow!!

* Expand readme
* Polish log files
* Add clean functions