Pasos:

1.- Transformar pdb (con la misma disposición de átomos que el itp) a pdbqt. Dos formas:
A. Usando un comando en la terminal, si se tiene instalado ADFR software suite, creados por el mismo laboratorio que AutoDock Vina. El comando tiene la forma:

prepare_receptor -r input_receptor.pdb -o output_receptor.pdbqt -U None

Donde input_receptor.pdb es el pdb que deseamos usar, y output_receptor.pdbqt es el nombre que le damos al pdbqt. Para más información:
https://autodock-vina.readthedocs.io/en/latest/docking_requirements.html

B. Usando AutoDock Tools.
File->Read molecule->Select pdb
Edit->Charges->Add Kollman Charges (placeholder charges)
Edit->Atoms->Assign AD4 type
File->Save->Write PDBQT->(Change name)->OK

2. Ejecutar el script de R. Si no es ejecutable, hacerlo con:
chmod +x itp_to_pdbqt.R

Tiene tres argumentos
-ic=file_name.itp          # input charges: el archivo itp
-ir=file_name.pdbqt        # input receptor: el archivo pdbqt
-o=given_name.pdbqt        # output: nombre para el pdbqt del output

Ejemplo:
./itp_to_pdbqt.R -ic=4ANP_FeIII.itp -ir=4ANP_FeIII.pdbqt -o=output_file.pdbqt

Si no se pone nombre, el archivo generado se llamará receptor_processed.pdbqt

Si no se tiene instalado el packete "stringr", es necesario ejecutar el comando como "sudo ./itp_to_pdbqt.R ..." para que instale automáticamente dicho paquete. En caso contrario, es necesario instalar el paquete por cuenta propia.