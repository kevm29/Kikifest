#!/usr/bin/env python3
"""
Convertisseur MotionTypes (.mt) -> Haxe 4 (.hx) pour le code de Hammerfest.

Il fait le gros du travail mécanique :
  - en-têtes de classes (packages), visibilité, `override`
  - types (int/float/bool/void, 'a), `downcast`, `upcast`, `Std.cast`, `callback`
  - boucles for C -> while (avec `continue` corrigé)
  - switch -> chaînes de if/else (pas de fallthrough en Haxe)
  - champs `$nom` -> `nom`, chaînes en apostrophes -> guillemets
  - points-virgules manquants en fin de ligne
Ce qui reste (erreurs de typage) se corrige à la main avec des patchs.

Usage : mt2hx.py <sortie> <racine1> [<racine2> ...]
"""
import os
import re
import sys

KEYWORDS = {
    "if", "else", "while", "for", "do", "switch", "case", "default", "break", "continue",
    "return", "var", "function", "class", "extends", "implements", "static", "private",
    "public", "new", "this", "super", "null", "true", "false", "interface", "native",
    "import", "in", "throw", "try", "catch",
}
HX_RESERVED = {"final", "inline", "dynamic", "macro", "operator", "enum", "abstract", "typedef", "using", "extern", "untyped", "package"}
TYPE_MAP = {"int": "Int", "float": "Float", "bool": "Bool", "void": "Void"}

# ---------------------------------------------------------------------------
# Tokenizer
# ---------------------------------------------------------------------------
TOKEN_RE = re.compile(r"""
    (?P<ws>[ \t\r\n]+)
  | (?P<lcomment>//[^\n]*)
  | (?P<bcomment>/\*.*?\*/)
  | (?P<str>"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')
  | (?P<tparam>'[a-z]\b)
  | (?P<num>0[xX][0-9a-fA-F]+|\d+\.\d*(?:[eE][-+]?\d+)?|\.\d+(?:[eE][-+]?\d+)?|\d+(?:[eE][-+]?\d+)?)
  | (?P<id>[A-Za-z_$][A-Za-z0-9_$]*)
  | (?P<op>>>>=|<<=|>>=|>>>|===|!==|\+\+|--|&&|\|\||==|!=|<=|>=|\+=|-=|\*=|/=|%=|&=|\|=|\^=|<<|>>|[-+*/%=<>!&|^~?:;,.(){}\[\]])
""", re.X | re.S)


class Tok:
    __slots__ = ("k", "v")

    def __init__(self, k, v):
        self.k = k
        self.v = v

    def __repr__(self):
        return f"{self.k}:{self.v!r}"


def tokenize(src):
    out = []
    i = 0
    n = len(src)
    while i < n:
        # 'a (paramètre de type) avant les chaînes
        m = re.compile(r"'[a-z]\b(?!')").match(src, i)
        if m and (i + 2 >= n or src[i + 2] != "'"):
            out.append(Tok("id", "Dynamic"))
            i = m.end()
            continue
        m = TOKEN_RE.match(src, i)
        if not m:
            raise SyntaxError(f"caractère inattendu {src[i]!r} à {i}: {src[i-40:i+40]!r}")
        k = m.lastgroup
        v = m.group(k)
        if k in ("lcomment", "bcomment"):
            k = "comment"
        out.append(Tok(k, v))
        i = m.end()
    return out


def sig(toks, i, step=1):
    """Index du prochain token significatif (hors espaces/commentaires)."""
    i += step
    while 0 <= i < len(toks) and toks[i].k in ("ws", "comment"):
        i += step
    return i


def match_close(toks, i):
    """toks[i] est ( [ ou { : renvoie l'index de la fermeture."""
    pairs = {"(": ")", "[": "]", "{": "}"}
    o = toks[i].v
    c = pairs[o]
    d = 0
    for j in range(i, len(toks)):
        t = toks[j]
        if t.k != "op":
            continue
        if t.v == o:
            d += 1
        elif t.v == c:
            d -= 1
            if d == 0:
                return j
    raise SyntaxError("parenthèse non fermée")


def text(toks):
    return "".join(t.v for t in toks)


def V(toks, i):
    return toks[i].v if 0 <= i < len(toks) else None


# ---------------------------------------------------------------------------
# Analyse des statements (pour for/switch/do)
# ---------------------------------------------------------------------------
def stmt_end(toks, i):
    """i = premier token significatif d'un statement ; renvoie l'index du dernier token."""
    v = toks[i].v
    if v == "{":
        return match_close(toks, i)
    if v in ("if", "while", "for", "switch") and toks[i].k == "id":
        p = sig(toks, i)
        pc = match_close(toks, p)
        if v == "switch":
            b = sig(toks, pc)
            return match_close(toks, b)
        body = sig(toks, pc)
        e = stmt_end(toks, body)
        if v == "if":
            nx = sig(toks, e)
            if V(toks, nx) == "else":
                return stmt_end(toks, sig(toks, nx))
        return e
    if v == "do" and toks[i].k == "id":
        body = sig(toks, i)
        e = stmt_end(toks, body)
        w = sig(toks, e)  # while
        p = sig(toks, w)
        pc = match_close(toks, p)
        s = sig(toks, pc)
        return s if V(toks, s) == ";" else pc
    if v == ";":
        return i
    # expression jusqu'au ; de profondeur 0
    j = i
    while j < len(toks):
        t = toks[j]
        if t.k == "op":
            if t.v in "([{":
                j = match_close(toks, j) + 1
                continue
            if t.v == ";":
                return j
            if t.v == "}":
                return sig(toks, j, -1)
        j += 1
    return len(toks) - 1


# ---------------------------------------------------------------------------
# Transformations
# ---------------------------------------------------------------------------
def fix_continue(body, incr):
    """Dans le corps d'une boucle for convertie, `continue` doit d'abord exécuter l'incrément."""
    out = []
    i = 0
    depth_fn = 0
    while i < len(body):
        t = body[i]
        if t.k == "id" and t.v in ("for", "while", "do"):
            # boucle imbriquée : ses continue ne nous concernent pas
            if t.v == "do":
                e = stmt_end(body, i)
            else:
                e = stmt_end(body, i)
            out.extend(body[i:e + 1])
            i = e + 1
            continue
        if t.k == "id" and t.v == "function":
            p = sig(body, i)
            while V(body, p) != "{":
                p = sig(body, p)
            e = match_close(body, p)
            out.extend(body[i:e + 1])
            i = e + 1
            continue
        if t.k == "id" and t.v == "continue" and incr.strip():
            out.append(Tok("raw", "{ " + incr + "; continue"))
            s = sig(body, i)
            if V(body, s) == ";":
                out.extend(body[i + 1:s + 1])
                out.append(Tok("raw", " }"))
                i = s + 1
            else:
                out.append(Tok("raw", "; }"))
                i += 1
            continue
        out.append(t)
        i += 1
    return out


def convert_for(toks):
    i = 0
    while i < len(toks):
        t = toks[i]
        if t.k == "id" and t.v == "for":
            p = sig(toks, i)
            pc = match_close(toks, p)
            inner = toks[p + 1:pc]
            semis = []
            d = 0
            for j, x in enumerate(inner):
                if x.k == "op" and x.v in "([{":
                    d += 1
                elif x.k == "op" and x.v in ")]}":
                    d -= 1
                elif x.k == "op" and x.v == ";" and d == 0:
                    semis.append(j)
            if len(semis) == 2:
                init = text(inner[:semis[0]]).strip()
                if not init.startswith("var"):
                    init = "; ".join(split_args(inner[:semis[0]]))
                cond = text(inner[semis[0] + 1:semis[1]]).strip() or "true"
                incr = text(inner[semis[1] + 1:]).strip()
                incr = incr.replace(",", ";")
                b = sig(toks, pc)
                e = stmt_end(toks, b)
                body = toks[b:e + 1]
                body = convert_for(body)
                body = fix_continue(body, incr)
                if body and body[0].v == "{":
                    btxt = text(body[1:-1])
                else:
                    btxt = text(body)
                init_s = (init + "; ") if init else ""
                incr_s = ("\n" + incr + ";") if incr else ""
                rep = "{ " + init_s + "while (" + cond + ") {" + btxt + incr_s + " } }"
                toks[i:e + 1] = [Tok("raw", rep)]
        i += 1
    return toks


def convert_switch(toks, warn):
    i = 0
    while i < len(toks):
        t = toks[i]
        if t.k == "id" and t.v == "switch":
            p = sig(toks, i)
            pc = match_close(toks, p)
            b = sig(toks, pc)
            be = match_close(toks, b)
            subj = text(toks[p + 1:pc]).strip()
            body = convert_switch(toks[b + 1:be], warn)
            # découpe en segments case/default
            segs = []  # (labels, tokens)
            cur = None
            j = 0
            while j < len(body):
                x = body[j]
                if x.k == "op" and x.v in "([{":
                    e = match_close(body, j)
                    if cur is not None:
                        cur[1].extend(body[j:e + 1])
                    j = e + 1
                    continue
                if x.k == "id" and x.v in ("case", "default"):
                    # label jusqu'au ':' de profondeur 0 (attention au ternaire, rare ici)
                    k = j + 1
                    d = 0
                    while True:
                        y = body[k]
                        if y.k == "op" and y.v in "([{":
                            d += 1
                        elif y.k == "op" and y.v in ")]}":
                            d -= 1
                        elif y.k == "op" and y.v == ":" and d == 0:
                            break
                        k += 1
                    label = None if x.v == "default" else text(body[j + 1:k]).strip()
                    if cur is not None and not any(tt.k not in ("ws", "comment") for tt in cur[1]):
                        cur[0].append(label)
                    else:
                        if cur is not None:
                            segs.append(cur)
                        cur = [[label], []]
                    j = k + 1
                    continue
                if cur is not None:
                    cur[1].append(x)
                j += 1
            if cur is not None:
                segs.append(cur)
            parts = []
            default = None
            for labels, stoks in segs:
                # retire les break de profondeur 0 ; signale un fallthrough
                clean = []
                ended = False
                nested_break = False
                k = 0
                while k < len(stoks):
                    x = stoks[k]
                    if x.k == "op" and x.v in "([{":
                        e = match_close(stoks, k)
                        chunk = stoks[k:e + 1]
                        if any(c.k == "id" and c.v == "break" for c in chunk):
                            # un break dans un sous-bloc sortirait de la boucle englobante en Haxe
                            if not re.search(r"\b(for|while|do)\b", text(chunk)):
                                nested_break = True
                        clean.extend(chunk)
                        k = e + 1
                        continue
                    if x.k == "id" and x.v == "break":
                        s = sig(stoks, k)
                        k = s + 1 if V(stoks, s) == ";" else k + 1
                        ended = True
                        continue
                    if x.k == "id" and x.v == "return":
                        ended = True
                    clean.append(x)
                    k += 1
                body_txt = text(clean)
                if nested_break:
                    # un break imbriqué sortait du switch : on l'émule avec do { } while (false)
                    if re.search(r"\bcontinue\b", body_txt):
                        warn(f"break + continue imbriqués dans switch({subj})")
                    body_txt = " do {" + body_txt + "} while (false); "
                has_code = bool(body_txt.strip())
                if has_code and not ended and (labels, stoks) is not segs[-1]:
                    warn(f"fallthrough possible dans switch({subj}) case {labels}")
                if None in labels:
                    default = body_txt
                    labels = [l for l in labels if l is not None]
                    if not labels:
                        continue
                cond = " || ".join(f"__sw == ({l})" for l in labels)
                parts.append((cond, body_txt))
            out = "{ var __sw:Dynamic = " + subj + ";\n"
            first = True
            for cond, btxt in parts:
                out += ("if" if first else "else if") + " (" + cond + ") {" + btxt + "}\n"
                first = False
            if default is not None:
                if first:
                    out += "{" + default + "}\n"
                else:
                    out += "else {" + default + "}\n"
            out += "}"
            toks[i:be + 1] = [Tok("raw", out)]
        i += 1
    return toks


def convert_wrappers(toks):
    """downcast(x) -> ((x):Dynamic), upcast(x)/Std.cast(x) -> (cast (x)), callback(o,f[,a]) -> closure."""
    i = 0
    while i < len(toks):
        t = toks[i]
        if t.k == "id" and t.v in ("downcast", "upcast", "callback") and V(toks, sig(toks, i)) == "(":
            prev = sig(toks, i, -1)
            if V(toks, prev) in (".", "function"):
                i += 1
                continue
            p = sig(toks, i)
            pc = match_close(toks, p)
            inner = convert_wrappers(toks[p + 1:pc])
            if t.v in ("downcast", "upcast"):
                inner = safe_nav(inner)  # downcast(a.b).c : a.b aussi doit tolérer undefined
            itxt = text(inner)
            if t.v == "downcast":
                rep = "((" + itxt + "):Dynamic)"
            elif t.v == "upcast":
                rep = "(cast (" + itxt + "))"
            elif t.v in ("int", "Int"):
                rep = "Std.int(" + itxt + ")"
            else:
                args = split_args(inner)
                if len(args) == 2:
                    rep = "(" + args[0].strip() + ")." + args[1].strip()
                else:
                    extra = ", ".join(a.strip() for a in args[2:])
                    rep = "(function(){ return (" + args[0].strip() + ")." + args[1].strip() + "(" + extra + "); })"
            toks[i:pc + 1] = [Tok("raw", rep)]
        elif t.k == "id" and t.v in ("Std", "MtStd") and V(toks, i + 1) == "." and V(toks, i + 2) == "cast":
            p = sig(toks, i + 2)
            pc = match_close(toks, p)
            itxt = text(convert_wrappers(toks[p + 1:pc]))
            toks[i:pc + 1] = [Tok("raw", "(cast (" + itxt + "))")]
        i += 1
    return toks


def split_args(toks):
    args = []
    cur = []
    d = 0
    for t in toks:
        if t.k == "op" and t.v in "([{":
            d += 1
        elif t.k == "op" and t.v in ")]}":
            d -= 1
        if t.k == "op" and t.v == "," and d == 0:
            args.append(text(cur))
            cur = []
        else:
            cur.append(t)
    args.append(text(cur))
    return args


def root_data(toks):
    """Dans les packages, `Data` désignait la classe Data racine (pas levels.Data)."""
    for i, t in enumerate(toks):
        if t.k == "id" and t.v == "Data" and V(toks, sig(toks, i, -1)) != "." and V(toks, sig(toks, i, -1)) not in ("class", "interface"):
            t.v = "RootData"
    return toks


def self_assign(toks):
    """`x = x;` dans un constructeur MotionTypes affectait le champ : -> this.x = x;"""
    for i, t in enumerate(toks):
        if t.k == "id" and V(toks, sig(toks, i)) == "=":
            r = sig(toks, sig(toks, i))
            if r < len(toks) and toks[r].k == "id" and toks[r].v == t.v and V(toks, sig(toks, r)) == ";" and V(toks, sig(toks, i, -1)) != ".":
                t.v = "this." + t.v
    return toks


PACKAGES = {"entity", "mode", "levels", "gui", "mtflash", "js", "swf", "mtlib", "haxe", "this", "super", "flash"}
ASSIGN_OPS = {"=", "+=", "-=", "*=", "/=", "%=", "&=", "|=", "^=", "<<=", ">>=", ">>>=", "++", "--"}


def safe_nav(toks):
    """
    AVM1 tolérait l'accès à un champ ou l'appel d'une méthode sur undefined (résultat undefined).
    En JS c'est une exception : on utilise la navigation sûre de Haxe (a?.b), sauf pour les
    chemins de types/packages et les cibles d'affectation.
    """
    n = len(toks)
    i = 0
    while i < n:
        t = toks[i]
        # début d'une chaîne d'accès : identifiant précédé d'autre chose qu'un point
        paren_root = False
        if t.k == "op" and t.v == "(":
            # (expr).a.b : expression parenthésée (ex. un downcast) suivie d'un accès
            pv = sig(toks, i, -1)
            c = match_close(toks, i)
            if (pv is None or not (toks[pv].k == "id" or toks[pv].v in (")", "]"))) and c + 2 < n \
                    and toks[c + 1].k == "op" and toks[c + 1].v == "." and toks[c + 2].k == "id":
                paren_root = True
        raw_root = t.k == "raw" and (t.v.startswith("((") or t.v.startswith("(cast (")) and t.v.endswith(")") \
            and i + 2 < n and toks[i + 1].k == "op" and toks[i + 1].v == "." and toks[i + 2].k == "id"
        if raw_root:
            paren_root = True
        if paren_root or (t.k == "id" and V(toks, sig(toks, i, -1)) not in (".", "?.") and V(toks, sig(toks, i, -1)) not in ("import", "package", "new", ":", "class", "extends", "implements")):
            # parcours de la chaîne
            dots = []
            j = match_close(toks, i) if (paren_root and not raw_root) else i
            root = "(expr)" if paren_root else t.v
            while True:
                k = j + 1  # pas d'espace attendu dans a.b
                if k < n and toks[k].k == "op" and toks[k].v in ("(", "["):
                    j = match_close(toks, k)
                    continue
                if k < n and toks[k].k == "op" and toks[k].v == "." and k + 1 < n and toks[k + 1].k == "id":
                    dots.append(k)
                    j = k + 1
                    continue
                break
            if dots:
                nxt = V(toks, sig(toks, j))
                is_type = root in PACKAGES or root[:1].isupper() or root.startswith("__") or root in ("untyped", "cast")
                if root == "this" and len(dots) > 1:
                    # this.a.b : this est sûr, mais pas this.a
                    is_type = False
                    dots = dots[1:]
                if not is_type and nxt not in ASSIGN_OPS:
                    for d in dots:
                        toks[d].v = "?."
                elif not is_type and nxt in ASSIGN_OPS and raw_root:
                    # ((x):Dynamic).a.b = v; -> écriture protégée
                    prev = V(toks, sig(toks, i, -1))
                    if prev is not None and toks[sig(toks, i, -1)].k == "raw" and prev.rstrip()[-1:] in (";", "}"):
                        prev = ";"
                    path = toks[i:dots[-1]]
                    if prev in (";", "{", "}", "else", None) and not any(x.k == "op" and x.v in ("(", "[") for x in path[1:]):
                        e = j
                        while e < n and not (toks[e].k == "op" and toks[e].v in (";", "}")):
                            if toks[e].k == "op" and toks[e].v in "([{":
                                e = match_close(toks, e)
                            e += 1
                        if e < n and toks[e].v == ";":
                            safe = "".join("?." if (x.k == "op" and x.v in (".", "?.")) else x.v for x in path)
                            toks[i] = Tok("raw", "{ if (" + safe + " != null) " + toks[i].v)
                            toks[e] = Tok("raw", "; }")
                elif not is_type and nxt in ASSIGN_OPS and not paren_root:
                    # écriture sur un objet peut-être undefined : on la protège (AVM1 l'ignorait)
                    prev = V(toks, sig(toks, i, -1))
                    if prev is not None and toks[sig(toks, i, -1)].k == "raw" and prev.rstrip()[-1:] in (";", "}"):
                        prev = ";"
                    path = toks[i:dots[-1]]
                    has_call = any(x.k == "op" and x.v == "(" for x in path)
                    if prev in (";", "{", "}", "else", None) and not has_call:
                        e = j
                        while e < n and not (toks[e].k == "op" and toks[e].v in (";", "}")):
                            if toks[e].k == "op" and toks[e].v in "([{":
                                e = match_close(toks, e)
                            e += 1
                        if e < n and toks[e].v == ";":
                            guard = text(path).replace("?.", ".")
                            safe = guard.replace(".", "?.")
                            toks[i] = Tok("raw", "{ if (" + safe + " != null) " + toks[i].v)
                            toks[e] = Tok("raw", "; }")
            i += 1
            continue
        i += 1
    return toks


def expr_start(toks, i):
    """Début de l'expression postfixe qui se termine juste avant toks[i]."""
    j = i - 1
    while j >= 0:
        t = toks[j]
        if t.k == "op" and t.v in ("]", ")"):
            # remonte à l'ouverture
            o = {"]": "[", ")": "("}[t.v]
            d = 0
            while j >= 0:
                if toks[j].k == "op" and toks[j].v == t.v:
                    d += 1
                elif toks[j].k == "op" and toks[j].v == o:
                    d -= 1
                    if d == 0:
                        break
                j -= 1
            j -= 1
            continue
        if t.k == "raw" and t.v.lstrip().startswith("{"):
            return j + 1
        if t.k in ("id", "raw", "str", "num"):
            j -= 1
            if j >= 0 and toks[j].k == "op" and toks[j].v in (".", "?."):
                j -= 1
                continue
            return j + 1
        return j + 1
    return 0


def double_index(toks):
    """a[i][j] en lecture : AVM1 renvoyait undefined si a[i] n'existait pas -> MtStd.ix(a[i], j)"""
    changed = True
    while changed:
        changed = False
        for i in range(len(toks) - 1):
            if toks[i].k == "op" and toks[i].v == "]" and toks[i + 1].k == "op" and toks[i + 1].v == "[":
                e2 = match_close(toks, i + 1)
                k = e2 + 1
                while k < len(toks):
                    if toks[k].k == "op" and toks[k].v in (".", "?.") and k + 1 < len(toks) and toks[k + 1].k == "id":
                        k += 2
                    elif toks[k].k == "op" and toks[k].v in ("[", "("):
                        k = match_close(toks, k) + 1
                    else:
                        break
                nxt = V(toks, sig(toks, k - 1))
                if nxt in ASSIGN_OPS:
                    continue
                start = expr_start(toks, i + 1)
                if start > i or start < 0:
                    continue
                base = text(toks[start:i + 1])
                idx = text(toks[i + 2:e2])
                toks[start:e2 + 1] = [Tok("raw", "MtStd.ix(" + base + ", " + idx + ")")]
                changed = True
                break
    return toks


def struct_ext_to_dynamic(toks):
    """{> MovieClip, champ:Type} (extension de classe) n'existe pas en Haxe -> Dynamic"""
    i = 0
    while i < len(toks):
        if toks[i].k == "op" and toks[i].v == "{" and V(toks, sig(toks, i)) == ">":
            e = match_close(toks, i)
            toks[i:e + 1] = [Tok("id", "Dynamic")]
        i += 1
    return toks


def simple_rewrites(toks):
    for i, t in enumerate(toks):
        if t.k == "id":
            if t.v in ("int", "float") and V(toks, sig(toks, i)) == "(" and V(toks, sig(toks, i, -1)) not in (".", "function"):
                t.v = "Std.int" if t.v == "int" else "(1.0*)"
            elif t.v in TYPE_MAP:
                t.v = TYPE_MAP[t.v]
            elif t.v in HX_RESERVED:
                t.v = t.v + "_"
            elif t.v.startswith("$") and len(t.v) > 1:
                # Haxe n'accepte pas $ dans les identifiants : __S_nom, remis en $nom après compilation
                t.v = "__S_" + t.v[1:]
            elif t.v == "Std":
                t.v = "MtStd"
            elif t.v == "string" and V(toks, sig(toks, i)) == "(" and V(toks, sig(toks, i, -1)) not in (".", "function"):
                t.v = "Std.string"
            elif t.v == "__TIME__":
                t.v = '"kikifest"'
            elif t.v == "Date" and V(toks, sig(toks, i, -1)) != ".":
                t.v = "js.lib.Date"
            elif t.v == "flash" and V(toks, i + 1) == ".":
                t.v = "mtflash"
            elif t.v == "fun" and V(toks, sig(toks, i)) == "(":
                t.v = "function"
            elif t.v in ("Xml", "XmlNode"):
                t.v = "Mt" + t.v
        elif t.k == "str" and t.v.startswith("'"):
            body = t.v[1:-1].replace("\\'", "'").replace('"', '\\"')
            t.v = '"' + body + '"'
        elif t.k == "num" and t.v.startswith("."):
            t.v = "0" + t.v
        elif t.k == "num" and re.match(r"^\d+\.$", t.v):
            t.v = t.v + "0"
    return toks


def is_do_while(toks, w):
    """toks[w] == 'while' : vrai si c'est la fin d'un do { } while (...)"""
    b = sig(toks, w, -1)
    if V(toks, b) != "}":
        return False
    d = 0
    j = b
    while j >= 0:
        if toks[j].k == "op" and toks[j].v == "}":
            d += 1
        elif toks[j].k == "op" and toks[j].v == "{":
            d -= 1
            if d == 0:
                return V(toks, sig(toks, j, -1)) == "do"
        j -= 1
    return False


def insert_semicolons(toks):
    """Ajoute les ; oubliés en fin de ligne (MotionTypes était tolérant)."""
    out = []
    n = len(toks)
    # mémorise pour chaque ')' le mot-clé qui précède la '(' correspondante
    header_close = set()
    for i, t in enumerate(toks):
        if t.k == "op" and t.v == "(":
            pv = V(toks, sig(toks, i, -1))
            if pv == "while" and is_do_while(toks, sig(toks, i, -1)):
                continue
            if pv in ("if", "while", "for", "switch", "catch") or (pv and toks[sig(toks, i, -1)].k == "id" and V(toks, sig(toks, sig(toks, i, -1), -1)) == "function"):
                try:
                    header_close.add(match_close(toks, i))
                except SyntaxError:
                    pass
    stack = []
    inserts = set()
    for i, t in enumerate(toks):
        out.append(t)
        if t.k == "op" and t.v in "([":
            stack.append("expr")
        elif t.k == "op" and t.v == "{":
            pv = V(toks, sig(toks, i, -1))
            stack.append("expr" if pv in ("=", "(", ",", ":", "return", "[", "?", "<", ">") else "block")
        elif t.k == "op" and t.v in ")]}":
            if t.v == "}" and stack and stack[-1] == "block":
                p = sig(toks, i, -1)
                pt = toks[p]
                if (pt.k in ("id", "num", "str", "raw") and pt.v not in ("else", "do", "return")) or \
                   (pt.k == "op" and pt.v in (")", "]", "++", "--") and p not in header_close):
                    inserts.add(p)
            if stack:
                stack.pop()
        if stack and stack[-1] == "expr":
            continue
        if t.k == "ws" and "\n" in t.v:
            p = sig(toks, i, -1)
            q = sig(toks, i - 1)  # premier significatif après ce ws
            if p < 0 or q >= n:
                continue
            pt, qt = toks[p], toks[q]
            prev_ends = (pt.k in ("id", "num", "str", "raw") and pt.v not in KEYWORDS - {"this", "null", "true", "false", "super"}) or \
                        (pt.k == "op" and pt.v in (")", "]", "++", "--") and p not in header_close)
            if pt.k == "id" and pt.v in ("else", "do", "return", "new", "in", "var", "function", "case", "default"):
                prev_ends = False
            next_starts = (qt.k == "id" and V(toks, sig(toks, q)) not in ("(",) and qt.v not in ("else", "in", "while", "catch")) or \
                          (qt.k == "id" and qt.v in ("if", "for", "while", "return", "var", "switch", "do", "break", "continue")) or \
                          (qt.k == "id" and V(toks, sig(toks, q)) == "(" and qt.v not in ("else",)) or \
                          (qt.k == "op" and qt.v == "}")
            if pt.k == "op" and pt.v == ">" and qt.k == "id" and qt.v.split(" ")[0] in ("public", "override", "var", "function", "static"):
                prev_ends = next_starts = True
            if prev_ends and next_starts:
                # pas de ; à l'intérieur d'un ( ) ou [ ] (expressions multi-lignes)
                inserts.add(p)
    res = []
    for i, t in enumerate(toks):
        res.append(t)
        if i in inserts:
            res.append(Tok("op", ";"))
    return res


def remove_empty_statements(toks):
    """Haxe refuse les ; isolés (`return x;;`, `{ ; }`)."""
    out = []
    for i, t in enumerate(toks):
        if t.k == "op" and t.v == ";":
            j = len(out) - 1
            while j >= 0 and out[j].k in ("ws", "comment"):
                j -= 1
            if j >= 0 and out[j].k == "op" and out[j].v in (";", "{"):
                continue
            if V(toks, sig(toks, i)) == ")":
                continue
        out.append(t)
    return out


# ---------------------------------------------------------------------------
# Classes : en-têtes, membres, override
# ---------------------------------------------------------------------------
class ClassInfo:
    def __init__(self, full, parent, methods, path):
        self.full = full
        self.parent = parent
        self.methods = methods
        self.path = path


def scan_class(toks):
    """Renvoie (nom complet, parent, méthodes, index token 'class')."""
    for i, t in enumerate(toks):
        if t.k == "id" and t.v in ("class", "interface"):
            j = sig(toks, i)
            name = ""
            while toks[j].k == "id" or toks[j].v == ".":
                name += toks[j].v
                j += 1
            parent = None
            k = sig(toks, j - 1)
            if V(toks, k) == "extends":
                k = sig(toks, k)
                parent = ""
                while toks[k].k == "id" or toks[k].v == ".":
                    parent += toks[k].v
                    k += 1
            # méthodes de niveau 1
            b = i
            while toks[b].v != "{":
                b += 1
            be = match_close(toks, b)
            methods = set()
            fields = set()
            d = 0
            for m in range(b, be):
                x = toks[m]
                if x.k == "op" and x.v == "{":
                    d += 1
                elif x.k == "op" and x.v == "}":
                    d -= 1
                elif d == 1 and x.k == "id" and x.v == "function":
                    nm = sig(toks, m)
                    if toks[nm].k == "id" and V(toks, sig(toks, m, -1)) != "static" and not is_static(toks, m):
                        methods.add(toks[nm].v)
                elif d == 1 and x.k == "id" and x.v == "var" and not is_static(toks, m):
                    nm = sig(toks, m)
                    fields.add(toks[nm].v)
            FIELDS.setdefault(name, fields)
            return name, parent, methods, i
    return None


FIELDS = {}
UNTYPED = set()


def ancestors_fields(full, classes):
    out = set()
    info = classes.get(full)
    seen = set()
    while info and info.parent and info.parent not in seen:
        seen.add(info.parent)
        pkg = info.full.rsplit(".", 1)[0] if "." in info.full else ""
        pname = resolve(info.parent, pkg, classes)
        if pname not in classes:
            break
        out |= FIELDS.get(pname, set())
        info = classes[pname]
    return out


def is_static(toks, i):
    j = sig(toks, i, -1)
    while j >= 0 and toks[j].k == "id" and toks[j].v in ("static", "private", "public"):
        if toks[j].v == "static":
            return True
        j = sig(toks, j, -1)
    return False


def resolve(name, pkg, classes):
    if name is None:
        return None
    if name in classes:
        return name
    if pkg and (pkg + "." + name) in classes:
        return pkg + "." + name
    return name


def ancestors_methods(full, classes):
    out = set()
    info = classes.get(full)
    seen = set()
    while info and info.parent and info.parent not in seen:
        seen.add(info.parent)
        pkg = info.full.rsplit(".", 1)[0] if "." in info.full else ""
        pname = resolve(info.parent, pkg, classes)
        pinfo = classes.get(pname)
        if pinfo is None:
            out |= EXTERN_METHODS.get(pname, set())
            break
        out |= pinfo.methods
        info = pinfo
    return out


# méthodes de swf.MovieClip qu'une classe du jeu pourrait redéfinir
EXTERN_METHODS = {
    "MovieClip": {"removeMovieClip", "play", "stop", "gotoAndStop", "gotoAndPlay", "nextFrame", "prevFrame", "swapDepths", "getDepth"},
}


def convert_members(toks, info, classes):
    """Ajoute public/override, type Dynamic aux champs et paramètres non typés."""
    name, parent, methods, ci = scan_class(toks)
    inherited = ancestors_methods(info.full, classes)
    b = ci
    while toks[b].v != "{":
        b += 1
    be = match_close(toks, b)
    i = b + 1
    d = 1
    while i < be:
        t = toks[i]
        if t.k == "op" and t.v == "{":
            d += 1
        elif t.k == "op" and t.v == "}":
            d -= 1
        elif d == 1 and t.k == "id" and t.v in ("var", "function"):
            # modificateurs déjà présents juste avant
            j = sig(toks, i, -1)
            mods = []
            start = i
            while toks[j].k == "id" and toks[j].v in ("static", "private", "public"):
                mods.append(toks[j].v)
                start = j
                j = sig(toks, j, -1)
            static = "static" in mods
            for m in range(start, i):
                if toks[m].k == "id" and toks[m].v in ("private", "public", "static"):
                    toks[m].v = ""
                    if m + 1 < len(toks) and toks[m + 1].k == "ws":
                        toks[m + 1].v = ""
            prefix = "public "
            if static:
                prefix += "static "
            if t.v == "function":
                nm = toks[sig(toks, i)].v
                if not static and nm != "new" and nm in inherited:
                    prefix = "override " + prefix
                # paramètres non typés -> Dynamic
                p = sig(toks, sig(toks, i))
                if V(toks, p) == "(":
                    pc = match_close(toks, p)
                    type_params(toks, p, pc)
                    # corps en `untyped` : les nombres AS2 mélangent librement entiers et flottants
                    b2 = sig(toks, pc)
                    if V(toks, b2) == ":":
                        b2 = sig(toks, b2)
                        if V(toks, b2) == "{":
                            b2 = sig(toks, match_close(toks, b2))
                    while b2 < len(toks) and V(toks, b2) not in ("{", ";"):
                        b2 = sig(toks, b2)
                    if V(toks, b2) == "{":
                        UNTYPED.add(id(toks[b2]))
            elif not static and toks[sig(toks, i)].v in ancestors_fields(info.full, classes):
                # champ déjà déclaré dans une classe parente : interdit en Haxe
                prefix = "// (déjà déclaré dans la classe parente) " + prefix
            else:
                # champ non typé : var x; ou var x = ...
                nm_i = sig(toks, i)
                nx = sig(toks, nm_i)
                if V(toks, nx) == ";":
                    toks[nm_i].v += ":Dynamic"
                elif V(toks, nx) == "=":
                    # type explicite d'après le littéral (sinon Haxe laisse parfois un monomorphe)
                    lit = sig(toks, nx)
                    after = sig(toks, lit)
                    neg = V(toks, lit) == "-"
                    if neg:
                        lit = sig(toks, lit)
                        after = sig(toks, lit)
                    if V(toks, after) in (";", None) or (toks[after].k == "ws"):
                        lt = toks[lit]
                        if lt.k == "num":
                            toks[nm_i].v += ":Float" if ("." in lt.v or "e" in lt.v.lower()) and not lt.v.lower().startswith("0x") else ":Int"
                        elif lt.k == "str":
                            toks[nm_i].v += ":String"
                        elif lt.v in ("true", "false"):
                            toks[nm_i].v += ":Bool"
            toks[i].v = prefix + t.v
        i += 1
    return toks


def add_super(toks):
    """Les constructeurs MotionTypes n'appelaient pas toujours super() : Haxe l'exige."""
    sc = scan_class(toks)
    if not sc or not sc[1]:
        return toks
    for i, t in enumerate(toks):
        if t.k == "id" and t.v.endswith("function") and V(toks, sig(toks, i)) == "new":
            p_ = sig(toks, sig(toks, i))
            pc_ = match_close(toks, p_)
            b_ = sig(toks, pc_)
            while V(toks, b_) != "{":
                b_ = sig(toks, b_)
            be_ = match_close(toks, b_)
            if not any(x.k == "id" and x.v == "super" for x in toks[b_:be_]):
                toks.insert(b_ + 1, Tok("raw", " super()"))
            break
    return toks


def type_params(toks, p, pc):
    """function f(a, b:Int) -> function f(a:Dynamic, b:Int)"""
    j = p + 1
    expect_name = True
    while j < pc:
        t = toks[j]
        if t.k == "op" and t.v == ",":
            expect_name = True
        elif t.k == "op" and t.v in "([{<":
            if t.v == "<":
                d = 1
                j += 1
                while j < pc and d:
                    if toks[j].v == "<":
                        d += 1
                    elif toks[j].v == ">":
                        d -= 1
                    j += 1
                continue
            j = match_close(toks, j)
        elif expect_name and t.k == "id":
            nx = sig(toks, j)
            if V(toks, nx) != ":":
                t.v += ":Dynamic"
            else:
                ty = sig(toks, nx)
                if V(toks, ty) in ("int", "float") and V(toks, sig(toks, ty)) in (",", ")", "="):
                    toks[ty].v = "Dynamic"
            expect_name = False
        j += 1


def type_locals(toks):
    """Variables locales non typées -> Dynamic (comme en AS2)."""
    for i, t in enumerate(toks):
        if t.k == "id" and t.v == "var":
            nm = sig(toks, i)
            while nm < len(toks) and toks[nm].k == "id":
                nx = sig(toks, nm)
                if V(toks, nx) in (";", ",", "=", "in", ")"):
                    toks[nm].v += ":Dynamic"
                # passe à la déclaration suivante (var a = 1, b = 2)
                j = nx
                d = 0
                while j < len(toks):
                    x = toks[j]
                    if x.k == "op" and x.v in "([{":
                        j = match_close(toks, j) + 1
                        continue
                    if x.k == "op" and x.v in (";", ")", "}"):
                        j = -1
                        break
                    if x.k == "op" and x.v == ",":
                        break
                    j += 1
                if j < 0 or j >= len(toks):
                    break
                nm = sig(toks, j)
    return toks


def header(toks, info):
    name, parent, methods, ci = scan_class(toks)
    j = sig(toks, ci)
    k = j
    while toks[k].k == "id" or toks[k].v == ".":
        k += 1
    short = name.rsplit(".", 1)[-1]
    toks[j:k] = [Tok("id", short)]
    pkg = name.rsplit(".", 1)[0] if "." in name else ""
    pre = ("package " + pkg + ";\n" if pkg else "package;\n") + "\nimport swf.*;\nimport mtlib.*;\nusing mtlib.StringExt;\n"
    if pkg:
        pre += "import Data as RootData;\n"
    return [Tok("raw", pre)] + toks, pkg, short


def remove_imports(toks):
    i = 0
    while i < len(toks):
        if toks[i].k == "id" and toks[i].v == "import":
            s = i
            while toks[s].v != ";":
                s += 1
            toks[i:s + 1] = []
            continue
        i += 1
    return toks


# ---------------------------------------------------------------------------
def main():
    out = sys.argv[1]
    roots = sys.argv[2:]
    files = []
    for r in roots:
        for dp, _, fs in os.walk(r):
            for f in fs:
                if f.endswith(".mt"):
                    files.append(os.path.join(dp, f))
    parsed = {}
    classes = {}
    for f in sorted(files):
        raw = open(f, "rb").read()
        try:
            src = raw.decode("utf-8-sig")
        except UnicodeDecodeError:
            src = raw.decode("latin-1")
        try:
            toks = tokenize(src)
            sc = scan_class(toks)
        except Exception as e:  # noqa
            print("IGNORÉ", f, e)
            continue
        if not sc:
            continue
        name, parent, methods, _ = sc
        classes[name] = ClassInfo(name, parent, methods, f)
        parsed[name] = toks
    warnings = []
    for name, toks in parsed.items():
        info = classes[name]

        def warn(msg, name=name):
            warnings.append(f"{name}: {msg}")

        try:
            pass  # les imports MotionTypes sont compatibles Haxe
            toks = convert_members(toks, info, classes)
            toks = add_super(toks)
            toks = struct_ext_to_dynamic(toks)
            if "." in name:
                toks = root_data(toks)
            toks = simple_rewrites(toks)
            toks = self_assign(toks)
            toks = type_locals(toks)
            toks = convert_wrappers(toks)
            toks = insert_semicolons(toks)
            toks = remove_empty_statements(toks)
            toks = safe_nav(toks)
            toks = double_index(toks)
            toks = convert_for(toks)
            toks = convert_switch(toks, warn)
            for t in toks:
                if id(t) in UNTYPED and t.v == "{":
                    t.v = " untyped {"
            toks, pkg, short = header(toks, info)
        except Exception as e:  # noqa
            warnings.append(f"{name}: ÉCHEC {e}")
            continue
        dest = os.path.join(out, *pkg.split(".")) if pkg else out
        os.makedirs(dest, exist_ok=True)
        with open(os.path.join(dest, short + ".hx"), "w", encoding="utf-8") as fh:
            fh.write("// Converti automatiquement depuis " + os.path.relpath(info.path, os.path.dirname(roots[0])) + " (Motion Twin)\n")
            out_txt = text(toks)
            # AVM1 tolérait `undefined.length` (comparaison fausse) : on protège les boucles
            out_txt = re.sub(r"while\s*\(\s*(\w+)\s*<\s*([\w.]+(?:\[\w+\])?)\.length\s*\)",
                             lambda m: f"while ({m.group(2)} != null && {m.group(1)}<{m.group(2)}.length)", out_txt)
            fh.write(out_txt)
    for w in warnings:
        print("ATTENTION", w)
    print(len(parsed), "classes converties")


if __name__ == "__main__":
    main()
