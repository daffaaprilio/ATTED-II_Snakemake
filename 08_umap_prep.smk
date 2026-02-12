import pandas as pd
import os
from collections import defaultdict


SP = config['sp']
wolf_sp = SP[0:3].lower()

rule all:
    input:
        f"release/v130/wolf/{wolf_sp}_aa_subgroup_table.txt",
        f"umap/atted.v130/.{SP}_subgroups_done"

rule subgroup_table:
    input:
        wolf=f"release/v130/wolf/{wolf_sp}_aa.wolf"
    output:
        table=f"release/v130/wolf/{wolf_sp}_aa_subgroup_table.txt"
    run:
        def create_subgroup_file(input_path, output_path, threshold=8):
            """
            遺伝子の局在情報ファイルを読み込み、しきい値を超える
            遺伝子IDとサブグループの対応リストを単一のファイルに出力する。
            """
            valid_pairs = set()

            try:
                with open(input_path, 'r', encoding='utf-8') as f:
                    for line in f:
                        if '|' not in line:
                            continue

                        line = line.strip()
                        parts = line.split(' ', 1)
                        if len(parts) < 2:
                            continue

                        id_part, data_part = parts
                        main_id = id_part.split('|')[0]
                        subgroup_entries = data_part.split(',')

                        for entry in subgroup_entries:
                            entry = entry.strip()
                            try:
                                subgroup_name, count_str = entry.rsplit(' ', 1)
                                count = int(count_str)
                                if count >= threshold:
                                    valid_pairs.add((main_id, subgroup_name))
                            except ValueError:
                                continue
            except FileNotFoundError:
                print(f"❌ エラー: 入力ファイル '{input_path}' が見つかりませんでした。")
                return

            sorted_pairs = sorted(list(valid_pairs), key=lambda x: (int(x[0]), x[1]))

            try:
                with open(output_path, 'w', encoding='utf-8') as f:
                    for gene_id, subgroup in sorted_pairs:
                        f.write(f"{gene_id} {subgroup}\n")
                print(f"✅ {os.path.basename(input_path)} → {os.path.basename(output_path)} に出力完了")
            except IOError:
                print(f"❌ エラー: 出力ファイル '{output_path}' に書き込めませんでした。")

        # Execute the function
        create_subgroup_file(str(input.wolf), str(output.table), threshold=8)

rule split_subgroup:
    input:
        coex_dir=f"umap/atted.v130/{SP}",
        mapfile=f"release/v130/wolf/{wolf_sp}_aa_subgroup_table.txt"
    output:
        f"umap/atted.v130/.{SP}_subgroups_done"
    run:
        def split_coexpression_data(coex_dir, mapfile, out_prefix):
            """
            元の共発現データディレクトリを、サブグループごとに分割するスクリプト。
            """
            # --- 1. マッピングファイルの読み込み ---
            print(f"📖 マッピングファイル '{mapfile}' を読み込んでいます...")
            subgroup_map = defaultdict(set)
            try:
                with open(mapfile, 'r', encoding='utf-8') as f:
                    for line in f:
                        parts = line.strip().split()
                        if len(parts) == 2:
                            gene_id, subgroup = parts
                            subgroup_map[subgroup].add(gene_id)
            except FileNotFoundError:
                print(f"❌ エラー: マッピングファイル '{mapfile}' が見つかりません。")
                return

            print(f"🗺️ {len(subgroup_map)} 個のサブグループが見つかりました: {', '.join(subgroup_map.keys())}")

            # --- 2. サブグループごとにループ処理 ---
            for subgroup, gene_ids_set in subgroup_map.items():
                # 新しい出力ディレクトリ名を作成 (例: atted.v130/Ath-u_nucl)
                output_dir_name = f"{out_prefix}_{subgroup}"
                output_path = os.path.join(os.path.dirname(coex_dir), output_dir_name)
                
                print("\n" + "="*50)
                print(f"⚙️ サブグループ '{subgroup}' の処理を開始します...")
                print(f"📂 出力先: {output_path}")
                os.makedirs(output_path, exist_ok=True)

                # --- 3. 共発現ファイルの分割 ---
                for gene_id in gene_ids_set:
                    original_file_path = os.path.join(coex_dir, gene_id)
                    
                    if not os.path.exists(original_file_path):
                        continue

                    try:
                        # 元の共発現ファイルを読み込む (ヘッダーなし、タブ区切り、1列目がインデックス)
                        df = pd.read_csv(original_file_path, sep='\t', header=None, index_col=0, names=['score'])
                        
                        # 同じサブグループに属する遺伝子のみにフィルタリング
                        df.index = df.index.map(str)
                        filtered_df = df[df.index.isin(gene_ids_set)]
                        
                        # 新しいファイルとして保存
                        new_file_path = os.path.join(output_path, gene_id)
                        filtered_df.to_csv(new_file_path, sep='\t', header=False)

                    except Exception as e:
                        print(f"   - ❌ エラー: ファイル '{original_file_path}' の処理中にエラーが発生しました: {e}")
                
                print(f"✅ サブグループ '{subgroup}' の処理が完了しました。")

            print("\n" + "="*50)
            print("🎉 全ての処理が完了しました。")

        # Execute the function
        split_coexpression_data(str(input.coex_dir), str(input.mapfile), SP)
