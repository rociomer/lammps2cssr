# lammps2cssr

## Description
BASH shell scripts for converting dump files from structural relaxations in
 LAMMPS to CSSR file format for use in molecular simulation software packages.
 Avoids using multiple different software packages by carrying out the
 conversion process in one simple (albeit slow) step.

*lamms2cssr-triclinic.sh* can convert dump files in which the box bounds are
 written for a triclinic simulation box. For more information on the
 relationship between the box bounds used in simulation and the triclinic
 lattice vectors (change of basis), see Section 6.12. "Triclinic
 (non-orthogonal) simulation boxes" under "How-to discussions" in the LAMMPS
 manual.

*lammps2cssr-ortho.sh* can convert dump files for simulations in which the box
 bounds are orthogonal.

## Instructions
Place trajectory snapshot in same directory as
 *lammps2cssr-{triclinic, orthogonal}.sh*. At the top of
 *lammps2cssr-{triclinic, orthogonal}.sh*, specify 1) the types of coordinates
 (fractional/Cartesian) to write to the CSSR and 2) the file extension for
 the dump files to convert. Then run the script. Make sure the script
 corresponds to the type of box bounds in the dump files.

## Comments
TODO: merge the triclinic and ortho scripts

TODO: rewrite in Python, this is too slow (can take up to 30 seconds for large
 structures)

## Author
Rocío Mercado

## Links 
Repository -- https://github.com/rociomer/lammps2cssr

LAMMPS Manual -- http://lammps.sandia.gov/doc/Section_howto.html
