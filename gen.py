import pandas as pd
import os
import sys
from datetime import datetime
import warnings

# Suprimir warnings específicos de openpyxl
warnings.filterwarnings("ignore", category=UserWarning, module='openpyxl')

def esperar_tecla():
    input("Presiona cualquier tecla para continuar...")

def convertir_fila_a_bsp(row, f):
    if isinstance(row["Fecha"], datetime):
        fecha = row["Fecha"]
    else:
        fecha = datetime.strptime(row["Fecha"], "%m/%d/%Y")
    
    fecha_formateada = fecha.strftime("%d%m%y")

    tipo_servicio = row["Tipo de Servicio"]
    service = "ISSUES"

    if tipo_servicio == "Air Ticket":
        tipo_boleto = "TKTT"
    elif tipo_servicio == "Debit Memo":
        tipo_boleto = "DM"
        service = "DEBIT MEMOS"
    elif tipo_servicio == "Credit Memo":
        tipo_boleto = "CM"
        service = "CREDIT MEMOS"
    elif tipo_servicio == "Exchange":
        tipo_boleto = "EX"
    elif tipo_servicio == "Refund":
        tipo_boleto = "RF"
        service = "REFUNDS" 
    else:
        tipo_boleto = "OT"

    def convert_to_bsp(value):
        if isinstance(value, (int, float)):
            value = str(value)
        elif isinstance(value, str):
            value = value.replace(',', '.')
        else:
            value = "0"
        try:
            return f"{float(value):.2f}".replace('.', '') 
        except ValueError:
            return "0".ljust(12, '0') 

    total_fare = convert_to_bsp(row['Total Fare USD'])
    service_fee = convert_to_bsp(row['Service Fee'])
    total_descuento = convert_to_bsp(row['Total a Descontar'])

    line1 = (
        f"DET{str(row['Ticket/Rsv #'])[:10].zfill(12)}FLGXBSP {service.ljust(20)}",
        f"{tipo_boleto}{str(row['Ticket/Rsv #'])[:10].ljust(10)}{fecha_formateada}",
        f"FFVVUSD{total_fare.ljust(12, '0')}{service_fee.ljust(12, '0')}0000000000000000000000000000000000000000000000000000000000000000000000000000",
        f"{total_descuento.ljust(12, '0')}000000000000000000000000I00000000000000000000000000Q"
    )
    f.write(''.join(line1) + '\n')

    if tipo_servicio in ["Air Ticket", "Exchange"]:
        line2 = (
            f"TAX{str(row['Ticket/Rsv #'])[:10].zfill(12)}FLGXBSP {service.ljust(20)}",
            f"{tipo_boleto}{str(row['Ticket/Rsv #'])[:10].ljust(10)}",
            f"XFBNA{convert_to_bsp(row['Total Fare USD'])}",
            f"XFMIA{convert_to_bsp(row['Service Fee'])}",
            f"XF00000000000ZP00000000000AY00000000000US00000000000"
        )
        f.write(''.join(line2) + '\n')

    if tipo_servicio == "Refund":
        line2 = (
            f"TAX{str(row['Ticket/Rsv #'])[:10].zfill(12)}FLGXBSP {service.ljust(20)}",
            f"RF{str(row['Ticket/Rsv #'])[:10].ljust(10)}",
            f"XFBNA{convert_to_bsp(row['Total Fare USD'])}",
            f"XFMIA{convert_to_bsp(row['Service Fee'])}",
            f"XF00000000000ZP00000000000AY00000000000US00000000000"
        )
        f.write(''.join(line2) + '\n')


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
