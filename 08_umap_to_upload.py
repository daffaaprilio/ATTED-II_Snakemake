from pathlib import Path
import shutil

WDIR = Path('/mnt/data2/daffa/Work/2025/11-ATTED-II_ver-13.0')
SOURCE_UMAP_RESULTS_PATH = Path(WDIR / 'umap/21.rotated_umap')
TARGET_UPLOAD_PATH = Path(WDIR / 'upload/coex/')

UMAP_RESULTS = []
for files in SOURCE_UMAP_RESULTS_PATH.iterdir():
    UMAP_RESULTS.append(files)

UPLOAD_DIRS = []

for items in TARGET_UPLOAD_PATH.iterdir():
    if items.exists():
        if items.is_dir() == True:
            UPLOAD_DIRS.append(items)
        else: 
            None
    else:
        None

# postpone Tae
UPLOAD_DIRS = [i for i in UPLOAD_DIRS if 'Tae-r' not in str(i)]
UMAP_RESULTS = [i for i in UMAP_RESULTS if 'Tae-r' not in str(i)]

# Get species from upload dirs - extract just the species part before .c
upload_species = {d.name.split('.')[0] for d in UPLOAD_DIRS}

# Copy matching umap files
for umap_file in UMAP_RESULTS:
    species = umap_file.stem.split('_')[0]
    if species in upload_species:
        target_dir = None
        for upload_dir in UPLOAD_DIRS:
            if upload_dir.name.startswith(species + '.'):
                target_dir = upload_dir
                break
        
        if target_dir and target_dir.exists():
            # Copy file
            dest_path = target_dir / umap_file.name
            shutil.copy2(umap_file, dest_path)
            
            # Rename with prefix
            version = target_dir.name  # e.g., 'Sbi-r.c1-0'
            base_name = umap_file.stem
            subgroup_name = base_name.replace(str(species), '')
            new_name = f"{version}{subgroup_name}.umap.txt"
            new_path = target_dir / new_name
            shutil.move(dest_path, new_path)
            
            print(f"Copied {umap_file.name} -> {target_dir.name}/{new_name}")
        else:
            print(f"Target does not exist for: {species}")