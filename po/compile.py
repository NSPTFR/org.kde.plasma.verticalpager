#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Nicolas POELAERT <claude@nspt.fr>
# SPDX-License-Identifier: GPL-2.0-or-later
"""Compile po/<lang>.po into the package's contents/locale/<lang>/LC_MESSAGES/*.mo.

Plasma looks up an applet's translations in that folder, under the
plasma_applet_<plugin id> domain. Does not need gettext to be installed.
Only handles plain msgid/msgstr entries (no plurals, no contexts).
"""

import ast
import pathlib
import struct

DOMAIN = "plasma_applet_org.kde.plasma.verticalpager"
ROOT = pathlib.Path(__file__).resolve().parent.parent


def parse_po(path):
    """Return {msgid: msgstr}, skipping untranslated and fuzzy entries."""
    messages = {}
    msgid = msgstr = None
    field = None
    fuzzy = False

    def flush():
        if msgid is not None and msgstr and not fuzzy:
            messages[msgid] = msgstr

    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line.startswith("#,") and "fuzzy" in line:
            fuzzy = True
        elif line.startswith("msgid "):
            flush()
            msgid, msgstr, field = ast.literal_eval(line[6:]), "", "msgid"
        elif line.startswith("msgstr "):
            msgstr, field = ast.literal_eval(line[7:]), "msgstr"
        elif line.startswith('"'):
            if field == "msgid":
                msgid += ast.literal_eval(line)
            else:
                msgstr += ast.literal_eval(line)
        elif not line:
            flush()
            msgid = msgstr = field = None
            fuzzy = False
    flush()
    return messages


def write_mo(messages, path):
    """Write a GNU .mo catalog (format described in the gettext manual)."""
    keys = sorted(messages)
    ids = [k.encode("utf-8") for k in keys]
    strs = [messages[k].encode("utf-8") for k in keys]

    header_size = 7 * 4
    table_size = len(keys) * 8
    ids_start = header_size + 2 * table_size
    strs_start = ids_start + sum(len(s) + 1 for s in ids)

    id_table, str_table = [], []
    offset = ids_start
    for s in ids:
        id_table += [len(s), offset]
        offset += len(s) + 1
    offset = strs_start
    for s in strs:
        str_table += [len(s), offset]
        offset += len(s) + 1

    data = struct.pack("<7I", 0x950412DE, 0, len(keys), header_size,
                       header_size + table_size, 0, 0)
    data += struct.pack(f"<{len(id_table)}I", *id_table)
    data += struct.pack(f"<{len(str_table)}I", *str_table)
    data += b"".join(s + b"\0" for s in ids)
    data += b"".join(s + b"\0" for s in strs)

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)


def main():
    for po in sorted((ROOT / "po").glob("*.po")):
        messages = parse_po(po)
        mo = ROOT / "contents" / "locale" / po.stem / "LC_MESSAGES" / f"{DOMAIN}.mo"
        write_mo(messages, mo)
        print(f"{po.relative_to(ROOT)} -> {mo.relative_to(ROOT)} ({len(messages) - 1} messages)")


if __name__ == "__main__":
    main()
