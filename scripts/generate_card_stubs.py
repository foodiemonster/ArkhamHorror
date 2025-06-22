import argparse
import csv
import json
import os
import re
import subprocess
from collections import OrderedDict
from zipfile import ZipFile

try:  # pragma: no cover - colab support
    from google.colab import files  # type: ignore
except Exception:  # pragma: no cover - allow running outside colab
    files = None


TEMPLATE_TOKENS = {
    '{open}': '{',
    '{close}': '}',
}

LOCATION_TEMPLATE = """module Arkham.Location.Cards.{module} ({varname}, {module}(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype {module} = {module} LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

{varname} :: LocationCard {module}
{varname} = location {module} Cards.{varname} {shroud} (Static {clues})

-- Card code: {card_id}
-- Class: {card_class}
-- Type: {card_type}
-- Traits: {traits}
-- Set: {set_name}
-- Encounter Set: {encounter_set}
-- Revealed Symbol: {rev_symbol}
-- Revealed Connections: {rev_conn}
-- Victory: {victory}
-- Unrevealed Card Id: {unrevealed_id}
-- Unrevealed Symbol: {unrev_symbol}
-- Unrevealed Connections: {unrev_conn}

-- Revealed Abilities:\n{revealed_abilities}
-- Unrevealed Abilities:\n{unrevealed_abilities}
-- TODO Card Text:\n{card_text}

instance HasAbilities {module} where
  getAbilities ({module} attrs) = extendRevealed attrs []

instance RunMessage {module} where
  runMessage msg l@({module} attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> {module} <$> liftRunMessage msg attrs
"""



def camel_to_var(name: str) -> str:
    return name[0].lower() + name[1:] if name else ''


def camel_to_words(name: str) -> str:
    out = []
    for c in name:
        if c.isupper() and out:
            out.append(' ')
        out.append(c)
    return ''.join(out)


def fmt_list(items: list[str]) -> str:
    return '[' + ', '.join(items) + ']'


def tokenize(value: str) -> str:
    parts = re.split(r"[^A-Za-z0-9]+", value)
    return ''.join(p.capitalize() for p in parts if p)


def parse_card_text(block: str) -> dict:
    data: dict[str, str] = {}
    for line in block.splitlines():
        line = line.strip()
        if not line:
            continue
        if line.startswith('-'):
            line = line[1:].strip()
        if ':' not in line:
            continue
        key, value = line.split(':', 1)
        data[key.strip()] = value.strip()
    return data


def load_projections(path: str = 'backend/.projections.json') -> dict:
    with open(path) as f:
        data = json.load(f)

    projections: dict[str, dict[str, str]] = {}
    for file_pattern, info in data.items():
        card_type = info.get('type')
        template = info.get('template')
        if not card_type or not template:
            continue
        dir_path = os.path.join('backend', file_pattern.replace('*.hs', ''))
        projections[card_type] = {
            'dir': dir_path,
            'template': '\n'.join(template),
        }
    return projections


def create_stub(card_type: str, name: str, projections: dict) -> str:
    info = projections.get(card_type)
    if info is None:
        raise ValueError(f"Unknown card type: {card_type}")
    os.makedirs(info['dir'], exist_ok=True)
    varname = camel_to_var(name)
    content = info['template']
    content = content.replace('{dot|snakecase|camelcase}', varname)
    content = content.replace('{dot}', name)
    for key, value in TEMPLATE_TOKENS.items():
        content = content.replace(key, value)
    file_path = os.path.join(info['dir'], f'{name}.hs')
    with open(file_path, 'w') as handle:
        handle.write(content + '\n')
    try:
        subprocess.run(['fourmolu', '-i', file_path], check=False)
    except FileNotFoundError:
        pass
    return file_path


def create_location_stub(data: dict, output_dir: str) -> str:
    file_name = data.get("File Name", "").replace(".hs", "")
    varname = camel_to_var(file_name)
    clues_raw = data.get("Clues", "0")
    per_player_flag = str(data.get("Per Player?", "")).strip().lower() in ["true", "yes"]
    clue_expr = f"(PerPlayer {clues_raw})" if per_player_flag else f"(Static {clues_raw})"
    rev_symbol = tokenize(data.get("Revealed Symbol", ""))
    rev_conn = [tokenize(t) for t in re.split(r",\s*", data.get("Revealed Connections", "")) if t]
    unrev_symbol_raw = data.get("Unrevealed Symbol", "")
    if unrev_symbol_raw.lower().startswith("same"):
        unrev_symbol = rev_symbol
    else:
        unrev_symbol = tokenize(unrev_symbol_raw) if unrev_symbol_raw else ""
    unrev_conn_raw = data.get("Unrevealed Connections", "")
    if unrev_conn_raw.lower().startswith("same"):
        unrev_conn = rev_conn
    else:
        unrev_conn = [tokenize(t) for t in re.split(r",\s*", unrev_conn_raw)] if unrev_conn_raw else []

    code = LOCATION_TEMPLATE.format(
        module=file_name,
        varname=varname,
        shroud=data.get("Shroud", "0"),
        clues=clue_expr,
        card_id=data.get("CardID", ""),
        card_class=data.get("Class", ""),
        card_type=data.get("Type", ""),
        traits=[tokenize(t) for t in re.split(r",\s*", data.get("Traits", "")) if t],
        set_name=tokenize(data.get("Set", "")),
        encounter_set=tokenize(data.get("Encounter", "")),
        rev_symbol=rev_symbol,
        rev_conn=rev_conn,
        victory=data.get("Victory", ""),
        unrevealed_id=data.get("Unrevealed CardID", ""),
        unrev_symbol=unrev_symbol,
        unrev_conn=unrev_conn,
        revealed_abilities=data.get("revealed_abilities", ""),
        unrevealed_abilities=data.get("unrevealed_abilities", ""),
        card_text=data.get("card_text", ""),
    )
    os.makedirs(output_dir, exist_ok=True)
    path = os.path.join(output_dir, f"{file_name}.hs")
    with open(path, "w") as out:
        out.write(code)
    try:
        subprocess.run(["fourmolu", "-i", path], check=False)
    except FileNotFoundError:
        pass
    return path


def append_comments(path: str, data: dict) -> None:
    comments = []
    if data.get("cost"):
        comments.append(f"-- Cost: {data['cost']}")
    if data.get("slot"):
        comments.append(f"-- Slot: {data['slot']}")
    if data.get("icons"):
        comments.append(f"-- Icons: {data['icons']}")
    if data.get("card_text"):
        comments.append("-- TODO Card Text:")
        comments.append("-- " + data["card_text"].replace("\n", "\n-- "))
    if not comments:
        return
    with open(path, "a") as handle:
        handle.write("\n" + "\n".join(comments) + "\n")
    try:
        subprocess.run(["fourmolu", "-i", path], check=False)
    except FileNotFoundError:
        pass


def generate_from_csv(
    csv_path: str,
    projections: dict,
    output_dir: str = "backend/arkham-api/library/Arkham/Location/Cards",
    snippet_path: str = "cards_snippet.txt",
    location_snippet_path: str = "location_snippet.txt",
) -> str:
    os.makedirs(output_dir, exist_ok=True)
    list_entries: list[str] = []
    def_entries: list[str] = []
    by_encounter: OrderedDict[str, list[str]] = OrderedDict()
    with open(csv_path, newline="") as handle:
        reader = csv.reader(handle)
        for row in reader:
            if not row:
                continue
            if row[0].strip().startswith("Card Text"):
                continue
            data = parse_card_text(row[0])
            if len(row) > 1:
                data["revealed_abilities"] = row[1].replace("\n", "\n-- ")
            if len(row) > 2:
                data["unrevealed_abilities"] = row[2].replace("\n", "\n-- ")
            if len(row) > 3:
                data["card_text"] = row[3].replace("\n", "\n-- ")
            if len(row) > 4:
                data["cost"] = row[4]
            if len(row) > 5:
                data["slot"] = row[5]
            if len(row) > 6:
                data["icons"] = row[6]
            card_type = data.get("Type", "").lower()
            if card_type == "location":
                path = create_location_stub(data, output_dir)
                varname = camel_to_var(data.get("File Name", ""))
                list_entries.append(f"  , {varname}")
                by_encounter.setdefault(data.get("Encounter", ""), []).append(varname)

                name_str = camel_to_words(data.get("File Name", ""))
                traits_str = fmt_list([tokenize(t) for t in re.split(r",\s*", data.get("Traits", "")) if t])
                rev_conn_str = fmt_list([tokenize(t) for t in re.split(r",\s*", data.get("Revealed Connections", "")) if t])
                if data.get("Unrevealed Symbol", ""):
                    unrev_conn_str = fmt_list([tokenize(t) for t in re.split(r",\s*", data.get("Unrevealed Connections", "")) if t])
                    def_body = [
                        "locationWithUnrevealed",
                        f'    "{data.get("CardID", "")}"',
                        f'    "{name_str}"',
                        f'    {traits_str}',
                        f'    {tokenize(data.get("Unrevealed Symbol", ""))}',
                        f'    {unrev_conn_str}',
                        f'    "{name_str}"',
                        f'    {traits_str}',
                        f'    {tokenize(data.get("Revealed Symbol", ""))}',
                        f'    {rev_conn_str}',
                        f'    {tokenize(data.get("Encounter", ""))}',
                    ]
                else:
                    def_body = [
                        "location",
                        f'    "{data.get("CardID", "")}"',
                        f'    "{name_str}"',
                        f'    {traits_str}',
                        f'    {tokenize(data.get("Revealed Symbol", ""))}',
                        f'    {rev_conn_str}',
                        f'    {tokenize(data.get("Encounter", ""))}',
                    ]
                victory = data.get("Victory", "")
                if victory.isdigit() and int(victory) > 0:
                    def_head = f"{varname} :: CardDef\n{varname} =\n  victory {victory} $ "
                else:
                    def_head = f"{varname} :: CardDef\n{varname} =\n  "
                def_entries.append(def_head + "\n    ".join(def_body))
            else:
                path = create_stub(card_type, data.get("File Name", ""), projections)
                append_comments(path, data)

    with open(snippet_path, "w") as handle:
        handle.write("-- Add these entries to allLocationCards:\n")
        handle.write("\n".join(list_entries))
        handle.write("\n\n-- Definitions:\n\n")
        handle.write("\n\n".join(def_entries))

    with open(location_snippet_path, "w") as handle:
        handle.write("-- Add these entries to allLocations:\n")
        for enc_set, vars in by_encounter.items():
            if not vars:
                continue
            handle.write(f"  , -- {enc_set}\n")
            handle.write(f"      SomeLocationCard {vars[0]}\n")
            for v in vars[1:]:
                handle.write(f"    , SomeLocationCard {v}\n")

    return snippet_path, location_snippet_path


def zip_output(directory: str, extra_files: list[str], zip_name: str = "generated_cards.zip") -> str:
    with ZipFile(zip_name, "w") as z:
        for root, _, files_in_dir in os.walk(directory):
            for f in files_in_dir:
                p = os.path.join(root, f)
                arc = os.path.relpath(p, start=directory)
                z.write(p, arc)
        for extra in extra_files:
            z.write(extra, os.path.basename(extra))
    return zip_name


def main() -> None:
    parser = argparse.ArgumentParser(description='Generate Haskell card stubs')
    sub = parser.add_subparsers(dest='cmd')

    single = sub.add_parser('create', help='Create a single card stub')
    single.add_argument('card_type', help='Card type (location, asset, act, etc)')
    single.add_argument('name', help='Module/Card name in CamelCase')

    csv_p = sub.add_parser('csv', help='Generate stubs from a CSV export')
    csv_p.add_argument('csv_file', help='Path to CSV file')
    csv_p.add_argument('--output', default='backend/arkham-api/library/Arkham/Location/Cards')
    csv_p.add_argument('--zip', action='store_true', help='Create a zip file with results')

    args = parser.parse_args()

    projections = load_projections()

    if args.cmd == 'csv':
        snippet, loc_snippet = generate_from_csv(args.csv_file, projections, args.output)
        if args.zip:
            zip_path = zip_output(args.output, [snippet, loc_snippet])
            print(f'Created {zip_path}')
        else:
            print(f'Wrote stubs to {args.output}')
    else:
        if files is not None and not args.cmd:
            uploaded = files.upload()
            if not uploaded:
                raise SystemExit('No CSV uploaded')
            csv_path = next(iter(uploaded))
            out_dir = 'generated_modules'
            os.makedirs(out_dir, exist_ok=True)
            snippet, loc_snippet = generate_from_csv(csv_path, projections, out_dir)
            zip_path = zip_output(out_dir, [snippet, loc_snippet])
            files.download(zip_path)
        else:
            if args.cmd != 'create':
                parser.error('No command provided')
            file_path = create_stub(args.card_type, args.name, projections)
            print(f'Created {file_path}')



    main()

def run_colab(csv_file_path=None, create_zip=True, output_dir="generated_modules"):
    try:
        from google.colab import files  # type: ignore
    except ImportError:
        files = None

    if files is not None and csv_file_path is None:
        print("📂 Upload your CSV file:")
        uploaded = files.upload()
        if not uploaded:
            raise RuntimeError("No CSV file uploaded.")
        csv_file_path = next(iter(uploaded))

    os.makedirs(output_dir, exist_ok=True)
    projections = load_projections()
    snippet, loc_snippet = generate_from_csv(csv_file_path, projections, output_dir)

    if create_zip:
        zip_path = zip_output(output_dir, [snippet, loc_snippet])
        print(f"✅ Created ZIP: {zip_path}")
        if files is not None:
            files.download(zip_path)
    else:
        print(f"✅ Stubs written to: {output_dir}")

# Disable CLI mode when running in Colab
if __name__ == "__main__":
    print("⚠️ This script is designed for use in Google Colab via `run_colab()`.")
