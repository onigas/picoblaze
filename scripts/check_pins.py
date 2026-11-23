"""Read-only check of active pin assignments against bundled Digilent master."""
from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
def assignments(path):
    result = {}
    for line in path.read_text().splitlines():
        m = re.search(r'PACKAGE_PIN\s+(\w+).*?\[get_ports\s+\{?([\w]+(?:\[\d+\])?)\}?\]', line)
        if m:
            assert m[2] not in result, 'Duplicate port: '+m[2]
            result[m[2]]=m[1]
    return result
active=assignments(root/'constraints/Basys3.xdc')
official=assignments(root/'docs/Basys-3-Master.xdc')
expected={'clk','btnC','btnU','btnD','btnL','btnR','dp','RsRx','RsTx'}
for name,count in [('sw',16),('led',16),('seg',7),('an',4)]:
    expected.update(f'{name}[{i}]' for i in range(count))
assert set(active)==expected, 'Missing or unexpected ports'
assert len(set(active.values()))==len(active), 'Pin collision'
for port,pin in active.items():
    assert official[port]==pin, f'Wrong pin for {port}'
print(f'PIN_CHECK_PASS: {len(active)} ports, unique pins, exact Digilent match')
