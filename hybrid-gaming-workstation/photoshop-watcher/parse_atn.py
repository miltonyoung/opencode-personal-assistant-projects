import struct
import sys


def read_unicode(data, off):
    n = struct.unpack_from('>I', data, off)[0]
    raw = data[off + 4:off + 4 + n * 2]
    return raw.decode('utf-16-be', errors='replace').rstrip('\x00'), off + 4 + n * 2


def extract_names(path):
    with open(path, 'rb') as f:
        data = f.read()

    if len(data) < 12:
        raise ValueError('File too short to be a valid ATN file')

    off = 0
    version = struct.unpack_from('>I', data, off)[0]
    off += 4

    # Basic sanity check for Photoshop .atn version (commonly 16)
    if version not in (12, 16):
        raise ValueError(f'Unsupported or invalid ATN version: {version}')

    set_name, off = read_unicode(data, off)

    if off >= len(data):
        raise ValueError('Truncated ATN file')

    expanded = data[off]
    off += 1

    action_count = struct.unpack_from('>I', data, off)[0]
    off += 4

    if action_count == 0:
        return set_name, [], version

    # Extract only the first action name. The watcher only needs the first
    # action in an ATN file; parsing the item bodies is fragile and can drift
    # into step/command strings (e.g., "copyToLayer").
    if off + 6 > len(data):
        raise ValueError('Truncated action header')
    off += 2  # index
    off += 1  # shiftKey
    off += 1  # commandKey
    off += 2  # colorIndex

    first_action_name, off = read_unicode(data, off)
    if not first_action_name:
        raise ValueError('Empty first action name')

    return set_name, [first_action_name], version


if __name__ == '__main__':
    for path in sys.argv[1:]:
        print(f'\n{path}')
        try:
            set_name, action_names, version = extract_names(path)
            print(f'  ATN version: {version}')
            print(f'  Action Set: {set_name}')
            print(f'  Actions ({len(action_names)}):')
            for name in action_names:
                print(f'    - {name}')
        except ValueError as e:
            print(f'  Error: {e}')
        except Exception as e:
            print(f'  Unexpected error: {e}')
