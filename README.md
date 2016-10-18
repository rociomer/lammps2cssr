# lammps2cssr

## Description
BASH shell scriptsfor converting dump files from structural relaxations in LAMMPS to .cssr file format for use in molecular simulation software packages. Avoids using multiple different software packages by carrying out the conversion process in one simple step.

lamms2cssr-triclinic.sh only supports dump files in which the orthogonal box bounds are written for a triclinic simulation box. For more information on the relationship between the orthogonal bounds and the triclinic lattice vectors, see Section 6.12. "Triclinic (non-orthogonal) simulation boxes" under "How-to discussions" in the LAMMPS manual.

lammps2cssr-ortho.sh can convert dump files for simulations in which the box bounds are orthogonal (and not converted from a triclinic cell).

## Instructions
Place trajectory snapshot in same directory as lammps2cssr\*.sh. At the top of lammps2cssr\*.sh, specify 1) the types of coordinates (fractional/Cartesian) to write to the .cssr and 2) the file extension for the dump files to convert. Then run lammps2cssr.sh.

## Author
Rocío Mercado

## Links 
Repository -- https://github.com/rociomer/lammps2cssr

LAMMPS Manual -- http://lammps.sandia.gov/doc/Section_howto.html
