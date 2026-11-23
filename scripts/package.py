"""Package only deliverables, excluding Vivado caches and simulation binaries."""
from pathlib import Path
import hashlib
import zipfile
root = Path(__file__).resolve().parents[1]
files = [root/'README_RO.md']
for folder in ('rtl','software','constraints','tools','scripts','sim','docs'):
    files.extend(p for p in (root/folder).rglob('*') if p.is_file()
                 and p.name != 'SHA256SUMS.txt' and '__pycache__' not in p.parts)
files.extend(p for p in (root/'output').glob('*') if p.suffix in ('.bit','.rpt'))
files = sorted(set(files))
manifest = root/'docs/SHA256SUMS.txt'
manifest.write_text(''.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.relative_to(root).as_posix()+'\n' for p in files))
files.append(manifest)
archive = root.parent/'PicoBlaze_Basys3_Vivado2022_2.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for p in files: z.write(p, root.name+'/'+p.relative_to(root).as_posix())
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert any(n.endswith('/output/PicoBlaze_Basys3.bit') for n in z.namelist())
print(str(archive))
print(f'{len(files)} files; {archive.stat().st_size} bytes; ZIP integrity PASS')
