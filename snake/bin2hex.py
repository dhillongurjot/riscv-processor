import struct
import sys

def convert(elf_binary, output_hex):
    with open(elf_binary, 'rb') as f:
        data = f.read()

    words = []
    for i in range(0, len(data), 4):
        chunk = data[i:i+4]
        if len(chunk) < 4:
            chunk = chunk + b'\x00' * (4 - len(chunk))
        word = struct.unpack('<I', chunk)[0]
        words.append(word)

    with open(output_hex, 'w') as f:
        for word in words:
            f.write(f'{word:08x}\n')

    print(f'Converted {len(words)} words to {output_hex}')

if __name__ == '__main__':
    convert('snake_text.bin', 'snake_imem.hex')