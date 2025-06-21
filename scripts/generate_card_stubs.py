import argparse
import json
import os
import subprocess


TEMPLATE_TOKENS = {
    '{open}': '{',
    '{close}': '}',
}


def camel_to_var(name: str) -> str:
    return name[0].lower() + name[1:] if name else ''


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


def main() -> None:
    parser = argparse.ArgumentParser(description='Generate Haskell card stubs')
    parser.add_argument('card_type', help='Card type (location, asset, act, etc)')
    parser.add_argument('name', help='Module/Card name in CamelCase')
    args = parser.parse_args()

    projections = load_projections()
    file_path = create_stub(args.card_type, args.name, projections)
    print(f'Created {file_path}')


if __name__ == '__main__':
    main()
