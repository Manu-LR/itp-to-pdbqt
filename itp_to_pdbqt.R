#!/usr/bin/env Rscript

args <- commandArgs(TRUE)
if("--help" %in% args){args[args=="--help"]<-"--help=help"}
## Parse arguments (we expect the form -arg value, except for --help)
parseArgs <- function(x) strsplit(sub("^-", "", x), "=")
argsL <- as.list(as.character(as.data.frame(do.call("rbind", parseArgs(args)))$V2))
names(argsL) <- as.data.frame(do.call("rbind", parseArgs(args)))$V1
args <- argsL
rm(argsL)
if("help" %in% args | is.null(args$ic) | is.null(args$ir)) {
  cat("
      Prerequisites: library stringr. If not installed, execute this script as sudo and it will be installed automatically. Otherwise, the user must install it independently. 

      Mandatory Arguments:
      -ic=file_name.itp      - Input charges: the itp file
      -ir=file_name.pdbqt    - Input receptor: the pdbqt file
      Optional Arguments:
      -o=output_name.pdbqt   - Output: name of the output pdbqt file
      --help                 - Prints these instructions
      
      If no output name is given, the output will be named as processed_receptor.pdbqt.

      Example:
      ./itp_to_pdbqt.R -ic=~/Path/to/file/4ANP_FeIII.itp -ir=~/Path/to/file/4ANP_FeIII.pdbqt -o=output_name.pdbqt \n\n")

  q(save="no")
}

if(length(find.package("stringr",quiet=TRUE))==0){install.packages("stringr")}
library(stringr)

### Charges ###
itp<-read.csv(args$ic, na.strings = "")
atoms_start<-which(itp=="[ atoms ]")  # The section with the charges is "[ atoms ]"
bonds_start<-which(itp=="[ bonds ]")  # Next section is consistently called "[ bonds ]"
df_atoms<-read.table(text=itp[(atoms_start+2):(bonds_start-1),], header=FALSE, na.strings = "") # Selects atoms and gives it dataframe format
# Column names: Extracts the first line after [ atoms ], gets rid of ";" and initial blank spaces, transforms it into dataframe
the_string<- read.table(text = (substr(itp[atoms_start+1,],4,nchar(itp[atoms_start+1,]))), na.strings="")
colnames(df_atoms)<-the_string
df_charges<-df_atoms[c("type","charge")]  # Dataframe with atoms and charges, in the correct order

All_C<-which(grepl("^C.*$",df_atoms$type))

# Loop that sums apolar H charges with its corresponding C, and saves the apolar H positions
apolar_H<-c()  # For saving the apolar H positions (rows will be deleted later)
for (i in All_C){
  one_C<-c(i)  # Carbon to evaluate
  j<-1         # Next position to the carbon
  while (grepl("^H.*$", df_charges$type[i+j])){
    one_C<-c(one_C, i+j)    # Saves the C position (plus previously found H), and the new H position
    j<-j+1     # index grows by 1 to evaluate if we find any other H
  }
  df_charges$charge[i]<-sum(df_charges$charge[one_C]) # Updates the C charge, adding its apolar H charges, if any
  apolar_H<-c(apolar_H, one_C[-1])                    # Generates a vector with apolar H positions
}

# In the pdbqt, we find four blank spaces after the last pdb line, followed by a space with "-" or nothing, and then 5 spaces, for a number with 3 decimals and the point separator.

# Rounds the charges to 3 decimals; then formats it into character type with 3 decimal points and "-" if negative, blank space if positive ("snmall" argument is mandatory); lastly, using str_pad it fills with blank spaces to the left up to a 10 characters length
charges_def<-str_pad(format(round(df_charges$charge, 3), nsmall=3), width=10, side="left", pad=" ")
if(any(nchar(charges_def)!=10)){print("FORMAT WARNING: unequal length for charges lines")}   # Same length for all charges

# Reads the pdbqt and loads it as a vector of lines
pdbqt_init<-read.csv(args$ir, header=FALSE, na.strings="")[,1]
if (grepl("^ATOM.*$", pdbqt_init[1])==FALSE){pdbqt_init<-pdbqt_init[-1]} # Deletes the initial remark if present
if(length(pdbqt_init)-1!=length(charges_def)){print("WARNING: Different number of atoms in pdbqt and itp")}
substr(pdbqt_init[1:(length(pdbqt_init)-1)],67,76)<-charges_def  # Substitutes the placeholder charges for the true ones
pdbqt_init<-pdbqt_init[-apolar_H]                                # Deletes the apolar H lines
new_numbers<-str_pad(seq(1,length(pdbqt_init),1), width=7, side="left", pad=" ") #There are 7 spaces for the atom numbering
if (any(nchar(new_numbers)!=7)==TRUE){print("WARNING: atom number format broken")}
substr(pdbqt_init,5,11)<-new_numbers                             # Renumbers tha atoms
pdbqt_init<-c("REMARK   4 XXXX COMPLIES WITH FORMAT V. 2.0",pdbqt_init)   # Adds the line ADT adds, just in case
if(("o" %in% names(args)) & (grepl("^.*\\.pdbqt$", args$o))){writeLines(pdbqt_init, args$o)}else{writeLines(pdbqt_init, "processed_receptor.pdbqt")}
