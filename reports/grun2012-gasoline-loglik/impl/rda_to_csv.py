# CC0. Minimal reader for R serialization format version 2 (XDR), enough to
# extract the data.frame stored in GasolineYield.rda (gzip of an RDX2 file).
# Written from R's documented serialization format (R-internals, "Serialization
# Format"). Prints the data frame as CSV on stdout: yield,batch,temp.
import gzip
import struct
import sys

NILVALUE, GLOBALENV, EMPTYENV, BASEENV, BASENAMESPACE = 254, 253, 242, 241, 247
MISSINGARG, UNBOUND, REFSXP = 251, 252, 255
NAMESPACESXP, PACKAGESXP, PERSISTSXP = 249, 248, 247
SYMSXP, LISTSXP, CLOSXP, ENVSXP, PROMSXP, LANGSXP = 1, 2, 3, 4, 5, 6
SPECIALSXP, BUILTINSXP, CHARSXP, LGLSXP, INTSXP, REALSXP = 7, 8, 9, 10, 13, 14
STRSXP, VECSXP, EXPRSXP, RAWSXP, S4SXP = 16, 19, 20, 24, 25


class Reader:
    def __init__(self, data):
        self.d = data
        self.p = 0
        self.refs = []

    def int(self):
        v = struct.unpack_from(">i", self.d, self.p)[0]
        self.p += 4
        return v

    def dbl(self):
        v = struct.unpack_from(">d", self.d, self.p)[0]
        self.p += 8
        return v

    def length(self):
        n = self.int()
        if n == -1:
            hi, lo = self.int(), self.int()
            n = (hi << 32) + lo
        return n

    def item(self):
        flags = self.int()
        typ = flags & 0xFF
        has_attr = bool(flags & (1 << 9))
        has_tag = bool(flags & (1 << 10))
        if typ == NILVALUE:
            return None
        if typ in (GLOBALENV, BASEENV, EMPTYENV, BASENAMESPACE, UNBOUND, MISSINGARG):
            return ("special", typ)
        if typ == REFSXP:
            idx = flags >> 8
            if idx == 0:
                idx = self.int()
            return self.refs[idx - 1]
        if typ == PERSISTSXP or typ == NAMESPACESXP or typ == PACKAGESXP:
            self.skip_strvec_into_refs()
            return ("ref", len(self.refs))
        if typ == SYMSXP:
            name = self.item()
            self.refs.append(("sym", name))
            return ("sym", name)
        if typ == ENVSXP:
            self.int()
            self.refs.append(("env",))
            for _ in range(3):
                self.item()
            return ("env",)
        if typ in (LISTSXP, LANGSXP, CLOSXP, PROMSXP):
            attr = self.item() if has_attr else None
            tag = self.item() if has_tag else None
            car = self.item()
            cdr = self.item()
            return ("pairlist", tag, car, cdr, attr) if typ == LISTSXP else ("lang", car, cdr)
        if typ in (SPECIALSXP, BUILTINSXP):
            n = self.int()
            self.p += n
            return ("builtin",)
        if typ == CHARSXP:
            n = self.int()
            if n == -1:
                return None
            s = self.d[self.p:self.p + n].decode("latin-1")
            self.p += n
            return s
        if typ in (LGLSXP, INTSXP):
            n = self.length()
            vals = list(struct.unpack_from(">%di" % n, self.d, self.p))
            self.p += 4 * n
            return self.finish_vector(("int", vals), has_attr)
        if typ == REALSXP:
            n = self.length()
            vals = list(struct.unpack_from(">%dd" % n, self.d, self.p))
            self.p += 8 * n
            return self.finish_vector(("real", vals), has_attr)
        if typ == STRSXP:
            n = self.length()
            vals = [self.item() for _ in range(n)]
            return self.finish_vector(("str", vals), has_attr)
        if typ in (VECSXP, EXPRSXP):
            n = self.length()
            vals = [self.item() for _ in range(n)]
            return self.finish_vector(("list", vals), has_attr)
        if typ == RAWSXP:
            n = self.length()
            self.p += n
            return self.finish_vector(("raw", n), has_attr)
        if typ == S4SXP:
            return self.finish_vector(("s4",), has_attr)
        raise ValueError("unsupported SEXP type %d at offset %d" % (typ, self.p))

    def skip_strvec_into_refs(self):
        self.int()  # placeholder flags for the string vector
        n = self.int()
        for _ in range(n):
            self.item()

    def finish_vector(self, value, has_attr):
        attr = self.item() if has_attr else None
        return ("vec", value, attr)


def attrs_to_dict(attr):
    out = {}
    while attr is not None and attr[0] == "pairlist":
        _, tag, car, cdr, _ = attr
        out[tag[1] if isinstance(tag, tuple) and tag[0] == "sym" else tag] = car
        attr = cdr
    return out


def main(path):
    raw = gzip.open(path).read()
    # .rda files start with the magic "RDX2\n" (or "RDX3\n") and then the stream.
    assert raw[:5] in (b"RDX2\n", b"RDX3\n"), "not an rda file"
    raw = raw[5:]
    assert raw[:2] == b"X\n", "not XDR format"
    r = Reader(raw[2:])
    version = r.int()
    r.int()
    r.int()
    assert version == 2, "expected RDX2 version 2, got %d" % version
    obj = r.item()
    # save() writes a pairlist: tag = object name, car = the object.
    assert obj[0] == "pairlist", "expected a pairlist from save()"
    value = obj[2]
    # value = ("vec", ("list", columns), attr) for the data.frame
    attr = attrs_to_dict(value[2])
    cols = value[1][1]
    names = attr["names"][1][1]
    cols_by_name = dict(zip(names, cols))
    yld = cols_by_name["yield"][1][1]
    temp = cols_by_name["temp"][1][1]
    batch_col = cols_by_name["batch"]
    batch_codes = batch_col[1][1]
    batch_attr = attrs_to_dict(batch_col[2])
    levels = batch_attr["levels"][1][1]
    print("yield,batch,temp")
    for y, b, t in zip(yld, batch_codes, temp):
        print("%.17g,%s,%.17g" % (y, levels[b - 1], t))


if __name__ == "__main__":
    main(sys.argv[1])
