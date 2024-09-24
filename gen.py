import pandas as pd
import os
import sys
from datetime import datetime
import warnings
import ciasAereas

# Suprimir warnings específicos de openpyxl
warnings.filterwarnings("ignore", category=UserWarning, module='openpyxl')

def esperar_tecla():
    input("Presiona cualquier tecla para continuar...")

def convertir_fila_a_bsp(row, f):
    ignore = False



    def convert_to_bsp(value, length=12):
        if isinstance(value, (int, float)):
            value = str(value)
        elif isinstance(value, str):
            value = value.replace(',', '.')
        else:
            value = "0"
        try:
            return f"{float(value):.2f}".replace('.', '').rjust(length, '0') 
        except ValueError:
            return "0".rjust(length, '0')




    codigo_aerea = row['Aerolínea'] 
    
    if pd.isna(codigo_aerea) or codigo_aerea is None:
        codigo_aerea = 'X1'
       
    try:
        cia_aerea = ciasAereas.obtener_codigo_numerico(codigo_aerea)
    except ValueError as e:
        print(e)
        cia_aerea = '995' 

    iata = "10638390"
    origen = "AGTDSTI".ljust(8)
    
    tipo_doc = ""
    clase = ""
    
    tipo_servicio = row["Tipo de Servicio"]
    service = "ISSUES"
    if tipo_servicio == "Air Extra": #En el TXT lo tengo como EMDA
        tipo_doc = "ISSUE"
        clase = "EMDA" 
    elif tipo_servicio == "GRP Deposit":
        tipo_doc = "ISSUE"
        clase = "EMDA" 
    elif tipo_servicio == "Air Ticket":
        tipo_doc = "ISSUE"
        clase = "TKTT" 
    elif tipo_servicio == "Debit Memo":
        tipo_doc = "DEBIT MEMOS"
        clase = "ADMA" 
    elif tipo_servicio == "Credit Memo":
        tipo_doc = "CREDIT MEMOS"
        clase = "ACMA" 
    elif tipo_servicio == "Exchange":
        tipo_doc = "ISSUE"
        clase = "TKTT" 
    elif tipo_servicio == "Refund":
        tipo_doc = "REFUNDS"
        clase = "RFND" 
    elif tipo_servicio == "Wire Transfer Received":
        ignore = True
    else: #Vacio/Grupo y Grupos
        tipo_doc = "ISSUE"
        clase = "TKTT" 
    
    boleto = str(row['Ticket/Rsv #'])[:10].ljust(10)
    if not row['Ticket/Rsv #']:
        ignore = True
    
    dv = "9" #No se de donde sale el dv
   
    
    
    
    
    
    if pd.isna(row["Fecha"]):
        fecha = datetime.now()  # O puedes establecer una fecha por defecto
    else:
        if isinstance(row["Fecha"], datetime):
            fecha = row["Fecha"]
        else:
            try:
                fecha = datetime.strptime(row["Fecha"], "%m/%d/%Y")
            except ValueError:
                print(f"Formato de fecha inválido en la fila {index}. Se usará la fecha actual.")
                fecha = datetime.now()
    emision = fecha.strftime("%y%m%d")
        
   
    cpns = "FFVV"
    currency = "USD2"
    
    
    total_fare = convert_to_bsp(row['Total Fare USD'])
    total_descuento = convert_to_bsp(row['Total a Descontar'])
    
    
    tarifa = "TARIFA".rjust(12, '0')
    porc_comision = "COM".rjust(4, '0')
    importe_comision = "IMPCOM".rjust(11, '0')
    porc_over = "PCOV".rjust(4, '0')
    importe_over = "IMPOV".rjust(11, '0')
    a_pagar = "APAG".rjust(12, '0')
    tax = "TAX".rjust(11, '0')
    fees = convert_to_bsp(row['Service Fee'],11) #Ver si son 11 o 12
    penalidad = "PENALIDAD".rjust(11, '#')
    
    tipo_de_ruta = "I"
    cash = "CASH".rjust(12, '0')
    uatp = "UATP".rjust(10, '0')
    refound = ""
    if tipo_doc == "REFOUNDS":
        refound = boleto
    
    if ignore == False:
        line1 = (
            f"DET{cia_aerea}{iata}{origen}{tipo_doc.ljust(20)}{clase.ljust(4)}",
            f"{boleto}{dv}{emision}{cpns}{currency}",
            f"{tarifa}{porc_comision}{importe_comision}{porc_over}{importe_over}{a_pagar}{tax}{fees}{penalidad}",
            f"{tipo_de_ruta}{cash}{uatp}{boleto}{refound}",
        )
        f.write(''.join(line1) + '\n')


# Parámetro
if len(sys.argv) > 1:
    xls_file = sys.argv[1]
else:
    xls_file = 'origen.xls'

print(f'Leyendo archivo XLS: {xls_file}...')

# Existe?
if not os.path.isfile(xls_file):
    print(f"Error: No se encontró el archivo '{xls_file}'.")
    esperar_tecla()
    sys.exit(1)

try:
    dfs = pd.read_excel(xls_file, sheet_name=None, engine='openpyxl')
except Exception as e:
    print(f"Error al leer el archivo '{xls_file}': {e}")
    esperar_tecla()
    sys.exit(1)

fecha_actual = datetime.now().strftime("%Y%m%d")
txt_file = f'destino_{fecha_actual}.txt'

with open(txt_file, 'w') as f:
    for sheet_name, df in dfs.items():
        if sheet_name.startswith("Estado de Cuenta") or sheet_name.startswith("Autogestión"):
            print(f'Procesando hoja: {sheet_name}')
            for index, row in df.iterrows():
                if index == 0:
                    continue  # Ignoro la primera fila porque aparentemente funciona como un subtítulo
                try:
                    convertir_fila_a_bsp(row, f)
                except Exception as e:
                    print(f"Error al procesar la fila {index} en la hoja '{sheet_name}': {e}")

print(f'Archivo TXT generado: {txt_file}')
esperar_tecla()
