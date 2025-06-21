import os
import csv
import re
import subprocess
from collections import OrderedDict
from zipfile import ZipFile

try:
    from google.colab import files  # type: ignore
except Exception:
    files = None

TEMPLATE = """module Arkham.Location.Cards.{module} ({varname}, {module}(..)) where

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
    return name[0].lower() + name[1:] if name else ""

def camel_to_words(name: str) -> str:
    out = []
    for c in name:
        if c.isupper() and out:
            out.append(" ")
        out.append(c)
    return "".join(out)

def fmt_list(items):
    return "[" + ", ".join(items) + "]"

def tokenize(value: str) -> str:
    parts = re.split(r"[^A-Za-z0-9]+", value)
    return "".join(p.capitalize() for p in parts if p)

def parse_card_text(block: str) -> dict:
    data: dict[str, str] = {}
    for line in block.splitlines():
        line = line.strip()
        if not line:
            continue
        if line.startswith("-"):
            line = line[1:].strip()
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        data[key.strip()] = value.strip()
    return data

def generate_modules(
    csv_path: str,
    output_dir: str = "backend/arkham-api/library/Arkham/Location/Cards",
    snippet_path: str = "cards_snippet.txt",
    location_snippet_path: str = "location_snippet.txt",
):
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

            card_id = data.get("CardID", "")
            file_name = data.get("File Name", "").replace(".hs", "")
            card_class = data.get("Class", "")
            card_type = data.get("Type", "")
            traits = [tokenize(t) for t in re.split(r",\s*", data.get("Traits", "")) if t]
            set_name = tokenize(data.get("Set", ""))
            encounter_raw = data.get("Encounter", "")
            encounter_set = tokenize(encounter_raw)
            rev_symbol = tokenize(data.get("Revealed Symbol", ""))
            rev_conn = [tokenize(t) for t in re.split(r",\s*", data.get("Revealed Connections", "")) if t]
            shroud = data.get("Shroud", "")
            clues = data.get("Clues", "")
            victory = data.get("Victory", "")
            unrevealed_id = data.get("Unrevealed CardID", "")
            unrev_symbol_raw = data.get("Unrevealed Symbol", "")
            unrev_conn_raw = data.get("Unrevealed Connections", "")
            if unrev_symbol_raw.lower().startswith("same"):
                unrev_symbol = rev_symbol
            else:
                unrev_symbol = tokenize(unrev_symbol_raw) if unrev_symbol_raw else ""
            if unrev_conn_raw.lower().startswith("same"):
                unrev_conn = rev_conn
            else:
                unrev_conn = [tokenize(t) for t in re.split(r",\s*", unrev_conn_raw)] if unrev_conn_raw else []

            revealed_abilities = row[1].replace("\n", "\n-- ")
            unrevealed_abilities = row[2].replace("\n", "\n-- ") if len(row) > 2 else ""
            varname = camel_to_var(file_name)
            code = TEMPLATE.format(
                module=file_name,
                varname=varname,
                shroud=shroud,
                clues=clues,
                card_id=card_id,
                card_class=card_class,
                card_type=card_type,
                traits=traits,
                set_name=set_name,
                encounter_set=encounter_set,
                rev_symbol=rev_symbol,
                rev_conn=rev_conn,
                victory=victory,
                unrevealed_id=unrevealed_id,
                unrev_symbol=unrev_symbol,
                unrev_conn=unrev_conn,
                revealed_abilities=revealed_abilities,
                unrevealed_abilities=unrevealed_abilities,
            )
            path = os.path.join(output_dir, f"{file_name}.hs")
            with open(path, "w") as out:
                out.write(code)
            try:
                subprocess.run(["fourmolu", "-i", path], check=False)
            except FileNotFoundError:
                pass

            list_entries.append(f"  , {varname}")

            by_encounter.setdefault(encounter_raw, []).append(varname)

            name_str = camel_to_words(file_name)
            traits_str = fmt_list(traits)
            rev_conn_str = fmt_list(rev_conn)
            if unrev_symbol:
                unrev_conn_str = fmt_list(unrev_conn)
                def_body = [
                    "locationWithUnrevealed",
                    f'    "{card_id}"',
                    f'    "{name_str}"',
                    f'    {traits_str}',
                    f'    {unrev_symbol}',
                    f'    {unrev_conn_str}',
                    f'    "{name_str}"',
                    f'    {traits_str}',
                    f'    {rev_symbol}',
                    f'    {rev_conn_str}',
                    f'    {encounter_set}',
                ]
            else:
                def_body = [
                    "location",
                    f'    "{card_id}"',
                    f'    "{name_str}"',
                    f'    {traits_str}',
                    f'    {rev_symbol}',
                    f'    {rev_conn_str}',
                    f'    {encounter_set}',
                ]
            if victory and victory.isdigit() and int(victory) > 0:
                def_head = f"{varname} :: CardDef\n{varname} =\n  victory {victory} $ "
            else:
                def_head = f"{varname} :: CardDef\n{varname} =\n  "
            def_entries.append(def_head + "\n    ".join(def_body))

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

if __name__ == "__main__":
    import argparse

    if files is not None:
        uploaded = files.upload()
        if not uploaded:
            raise SystemExit("No CSV uploaded")
        csv_path = next(iter(uploaded))
        out_dir = "generated_modules"
        os.makedirs(out_dir, exist_ok=True)
        snippet, loc_snippet = generate_modules(csv_path, out_dir)
        zip_path = zip_output(out_dir, [snippet, loc_snippet])
        files.download(zip_path)
    else:
        parser = argparse.ArgumentParser(description="Generate Haskell card modules from CSV")
        parser.add_argument("csv_file", help="Path to CSV file")
        parser.add_argument(
            "--output",
            default="backend/arkham-api/library/Arkham/Location/Cards",
            help="Output directory",
        )
        args = parser.parse_args()
        snippet, loc_snippet = generate_modules(args.csv_file, args.output)
        zip_path = zip_output(args.output, [snippet, loc_snippet])
        print(f"Created {zip_path}")
