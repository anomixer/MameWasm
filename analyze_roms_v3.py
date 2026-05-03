
import subprocess
import xml.etree.ElementTree as ET
import os

# Configuration - Adjust these paths as needed
# For best results, place a native MAME executable in the 'bin' folder
LST_PATH = os.path.join(os.path.dirname(__file__), 'custom_targets', 'ample.lst')
MAME_EXE = os.path.join(os.path.dirname(__file__), 'bin', 'mame.exe')

# Fallback to system PATH if local bin doesn't have it
if not os.path.exists(MAME_EXE):
    MAME_EXE = 'mame' 

def get_drivers():
    if not os.path.exists(LST_PATH):
        print(f"Error: {LST_PATH} not found.")
        return []
    with open(LST_PATH, 'r') as f:
        return [line.strip() for line in f if line.strip()]

# Cache for XML data to avoid calling MAME too many times
DRIVER_CACHE = {}

def get_driver_info(driver):
    if driver in DRIVER_CACHE: return DRIVER_CACHE[driver]
    
    cmd = [MAME_EXE, '-listxml', driver]
    res = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8', errors='ignore')
    if res.returncode != 0: return None
    
    try:
        root = ET.fromstring(res.stdout)
        machine = root.find('machine')
        if machine is None: return None
        
        info = {
            'romof': machine.get('romof'),
            'devices': set()
        }
        
        # Check for devices mentioned in ROM requirements or device_ref
        # MAME -listroms is actually more concise for devices
        cmd_roms = [MAME_EXE, '-listroms', driver]
        res_roms = subprocess.run(cmd_roms, capture_output=True, text=True, encoding='utf-8', errors='ignore')
        for line in res_roms.stdout.splitlines():
            if 'including devices' in line:
                start = line.find('including devices "')
                if start != -1:
                    dev_part = line[start + 19 : line.rfind('")')]
                    devs = dev_part.replace('"', '').split(', ')
                    info['devices'].update(devs)
        
        DRIVER_CACHE[driver] = info
        return info
    except:
        return None

def get_full_stack(driver):
    stack = [driver]
    visited = {driver}
    
    current = driver
    while True:
        info = get_driver_info(current)
        if not info: break
        
        # Add devices from this level
        for dev in info['devices']:
            if dev not in visited:
                stack.append(dev)
                visited.add(dev)
        
        # Move up to parent
        parent = info['romof']
        if parent and parent not in visited:
            stack.append(parent)
            visited.add(parent)
            current = parent
        else:
            break
            
    # Deduplicate and format
    return ";".join([z + ".zip" for z in stack if z])

drivers = get_drivers()
results = {}
print("Analyzing all drivers with v3 (Recursive XML + ROMS)...")
for d in drivers:
    deps = get_full_stack(d)
    results[d] = deps
    print(f"{d}: {deps}")

output_file = os.path.join(os.path.dirname(__file__), 'rom_mapping_results_v3.txt')
with open(output_file, 'w') as f:
    for d, z in results.items():
        f.write(f"  {d}: '{z}',\n")

print("Done! v3 results saved.")
