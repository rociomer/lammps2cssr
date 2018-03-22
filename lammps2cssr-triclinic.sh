#!/bin/bash

                          ### SET VARIABLES HERE ###                           
###############################################################################
FRACTIONAL=true # true for fractional, false for Cartesian
lammpsTrjExt="lammpstrj" # LAMMPS dump trajectory extension
###############################################################################


min() 
{
  printf "%s\n" "$@" | sort -g | head -1
}


max() 
{
  printf "%s\n" "$@" | sort -g | tail -1
}


sin()
{
  # input in degrees and converted to radians
  echo "s($1*0.01745329251)" | bc -l
}


cos()
{
  # input in degrees and converted to radians
  echo "c($1*0.01745329251)" | bc -l
}


acos()
{
  # output in degrees
  if (( $(echo "$1 == 0" | bc -l) )); then 
      echo "a(1)*2/0.01745329251" | bc -l
  elif (( $(echo "(-1 <= $1) && ($1 < 0)" | bc -l) )); then
      echo "(a(1)*4 - a(sqrt((1/($1^2))-1)))/0.01745329251" | bc -l
  elif (( $(echo "(0 < $1) && ($1 <= 1)" | bc -l) )); then
      echo "a(sqrt((1/($1^2))-1))/0.01745329251" | bc -l
  else
      echo "acos input out of range"
      return 1
  fi
}


round()
{
  digits=$2
  echo $1 | xargs printf "%.*f\n" ${digits}
}


getBoxBounds()
{
  ###########################################################################
  # Box bounds for a triclinic unit cell in LAMMPS are written to a dump file 
  # such that an orthogonal bounding box actually encloses the triclinic 
  # simulation box, with 3 tilt factors (xy, xz, yz) defined. This format for 
  # the BOX BOUNDS is as follows:
  # ITEM: BOX BOUNDS xy xz yz
  # xlo_bound xhi_bound xy
  # ylo_bound yhi_bound xz
  # zlo_bound zhi_bound yz
  ###########################################################################
  BoxBounds=($(grep -A 3 "BOX BOUNDS xy xz yz" $1))
  xlo_bound=$(printf "%.6f * 1\n" ${BoxBounds[9]} | bc -l)
  xhi_bound=$(printf "%.6f * 1\n" ${BoxBounds[10]} | bc -l)
  ylo_bound=$(printf "%.6f * 1\n" ${BoxBounds[12]} | bc -l)
  yhi_bound=$(printf "%.6f * 1\n" ${BoxBounds[13]} | bc -l)
  zlo_bound=$(printf "%.6f * 1\n" ${BoxBounds[15]} | bc -l)
  zhi_bound=$(printf "%.6f * 1\n" ${BoxBounds[16]} | bc -l)
  xy=$(printf "%.6f * 1\n" ${BoxBounds[11]} | bc -l)
  xz=$(printf "%.6f * 1\n" ${BoxBounds[14]} | bc -l)
  yz=$(printf "%.6f * 1\n" ${BoxBounds[17]} | bc -l)
} 
   
getTriclinicBoxParameters()
{
  ###########################################################################
  # The relationship between the bounding box and the triclinic box
  # parameters is such that:
  # xlo = xlo_bound - MIN(0.0,xy,xz,xy+xz)
  # xhi = xhi_bound - MAX(0.0,xy,xz,xy+xz)
  # ylo = ylo_bound - MIN(0.0,yz)
  # yhi = yhi_bound - MAX(0.0,yz)
  # zlo = zlo_bound
  # zhi = zhi_bound 
  ###########################################################################
  xlo=$(echo "$1 - $(min 0.0 $7 $8 $(echo "$7 + $8" | bc -l))" | bc -l)
  xhi=$(echo "$2 - $(max 0.0 $7 $8 $(echo "$7 + $8" | bc -l))" | bc -l)
  ylo=$(echo "$3 - $(min 0.0 $9)" | bc -l)
  yhi=$(echo "$4 - $(max 0.0 $9)" | bc -l)
  zlo=$5
  zhi=$6
}


getBoxSize()
{
  ###########################################################################
  # The box lengths (lx, ly, lz) can be obtained from:
  # lx = xhi - xlo
  # ly = yhi - ylo
  # lz = zhi - zlo
  ###########################################################################
  lx=$(echo "$1 - $2" | bc -l)
  ly=$(echo "$3 - $4" | bc -l)
  lz=$(echo "$5 - $6" | bc -l)

}


getLatticeConstants()
{
  ###########################################################################
  # The relationship between the lattice constants for the triclinic unit 
  # cell and the orthogonal bounding box lengths and tilt factors is then:
  # a = lx 
  # b = sqrt( ly^2 + xy^2 )
  # c = sqrt( lz^2 + xz^2 + yz^2 )
  ###########################################################################
  a=$1 
  b=$(echo "sqrt( $2^2 + $4^2 )/1" | bc -l)
  c=$(echo "sqrt( $3^2 + $5^2 + $6^2 )/1" | bc -l)
}


getLatticeAngles()
{
  ###########################################################################
  # The relationship between the lattice angles for the triclinic unit 
  # cell and the orthogonal bounding box lengths and tilt factors is then:
  # alpha = arccos( (xy*xz + ly*xz)/(b*c) )
  # beta  = arccos( xz/c )
  # gamma = arccos( xy/b )
  ###########################################################################
  alpha=$(echo $(acos $(echo "($4 * $5 + $3 * $6) / ($1 * $2)" | bc -l)))
  beta=$(echo $(acos $(echo "$5/$2" | bc -l)))
  gamma=$(echo $(acos $(echo "$4/$1" | bc -l)))
}


getNumberOfAtoms()
{
  numberOfAtoms=($(grep -A 1 "NUMBER OF ATOMS" $i))
  echo ${numberOfAtoms[4]}
}


writeCartesianCSSR()
{
  cssrFile=$(echo "${1%.lammpstrj}.cssr")
  echo "                        $(round $2 4) $(round $3 4) $(round $4 4)" \
  > $cssrFile
  echo "          $(round $5 4) $(round $6 4) $(round $7 4)   SPGR = 1 P 1 \
  OPT = 1" >> $cssrFile
  echo "$8   1" >> $cssrFile
  echo "0 ${1%.lammpstrj} : ${1%.lammpstrj}" >> $cssrFile
  grep -A $8 "ITEM: ATOMS element x y z" $1 | tail -$8 > tmpCoordinates
  count=1
  cat tmpCoordinates | while read line; do
    echo " $count $line  0  0  0  0  0  0  0  0  0.000000" >> tmpCSSR
    let count+=1
  done
  cat tmpCSSR | column -t >> $cssrFile
  rm tmpCSSR tmpCoordinates
}


writeFractionalCSSR()
{
  cssrFile=$(echo "${1%.lammpstrj}.cssr")
  echo "                        $(round $2 4) $(round $3 4) $(round $4 4)" \
  > $cssrFile
  echo "          $(round $5 4) $(round $6 4) $(round $7 4)   SPGR = 1 P 1 \
  OPT = 1" >> $cssrFile
  echo "$8   0" >> $cssrFile
  echo "0 ${1%.lammpstrj} : ${1%.lammpstrj}" >> $cssrFile
  grep -A $8 "ITEM: ATOMS element x y z" $1 | tail -$8 > tmpCoordinates
  cellVolume=$(echo "sqrt(1.0 - $(cos $5)^2 - $(cos $6)^2 - $(cos $7)^2 + \
  2*$(cos $5)*$(cos $6)*$(cos $7))" | bc -l)
  count=1
  cat tmpCoordinates | while read line; do
    lineList=(${line})
    xFrac=$(echo "${lineList[1]}/$2 - ${lineList[2]}*$(cos $7)/($2*$(sin $7)) \
    + ${lineList[3]}*($(cos $5)*$(cos $7) \
    - $(cos $6))/($2*$cellVolume*$(sin $7))" | bc -l)
    yFrac=$(echo "${lineList[2]}/($3*$(sin $7)) + \
    ${lineList[3]}*($(cos $6)*$(cos $7) - \
    $(cos $5))/($3*$cellVolume*$(sin $7))" | bc -l)
    zFrac=$(echo "${lineList[3]}*$(sin $7)/($4*$cellVolume)" | bc -l)
    if [ $(echo $xFrac'>'1.0 | bc -l) -eq 1 ]; then 
      xFrac=$(echo "$xFrac - ${xFrac%.*}" | bc -l) # shift back into unit cell 
    fi
    if [ $(echo $yFrac'>'1.0 | bc -l) -eq 1 ]; then 
      yFrac=$(echo "$yFrac - ${yFrac%.*}" | bc -l) # shift back into unit cell 
    fi
    if [ $(echo $zFrac'>'1.0 | bc -l) -eq 1 ]; then 
      zFrac=$(echo "$zFrac - ${zFrac%.*}" | bc -l) # shift back into unit cell 
    fi
    echo " $count ${lineList[0]} $(round $xFrac 6) $(round $yFrac 6) \
    $(round $zFrac 6) 0  0  0  0  0  0  0  0  0.000000" >> tmpCSSR
    let count+=1
  done
  cat tmpCSSR | column -t >> $cssrFile
  rm tmpCSSR tmpCoordinates
}

main()
{
  for i in *.$lammpsTrjExt; do
    getBoxBounds $i
    getTriclinicBoxParameters $xlo_bound $xhi_bound $ylo_bound $yhi_bound \
      $zlo_bound $zhi_bound $xy $xz $yz
    getBoxSize $xhi $xlo $yhi $ylo $zhi $zlo 
    getLatticeConstants $lx $ly $lz $xy $xz $yz
    getLatticeAngles $b $c $ly $xy $xz $yz
    atomsInStructure=$(getNumberOfAtoms $i)
    if $FRACTIONAL ; then
      writeFractionalCSSR $i $a $b $c $alpha $beta $gamma $atomsInStructure
    else
      writeCartesianCSSR $i $a $b $c $alpha $beta $gamma $atomsInStructure
    fi 
  done
}

main
