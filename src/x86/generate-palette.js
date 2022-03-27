function HSVToRGB(h, s, v) {

    var r, g, b, i, f, p, q, t;
    if (arguments.length === 1) {
        s = h.s, v = h.v, h = h.h;
    }
    i = Math.floor(h * 6);
    f = h * 6 - i;
    p = v * (1 - s);
    q = v * (1 - f * s);
    t = v * (1 - (1 - f) * s);
    switch (i % 6) {
        case 0: r = v, g = t, b = p; break;
        case 1: r = q, g = v, b = p; break;
        case 2: r = p, g = v, b = t; break;
        case 3: r = p, g = q, b = v; break;
        case 4: r = t, g = p, b = v; break;
        case 5: r = v, g = p, b = q; break;
    }
    return [
        Math.round(r * 63),
        Math.round(g * 63),
        Math.round(b * 63)
    ];
}

function toHex(n) {
    return "0x" + n.toString(16).padStart(2, "0")
}

for (let j = 0; j < 64; j++) {
    let st = '';
    for (let i = 0; i < 4; i++) {
        let c = j * 4 + i;

        const [r, g, b] = (c >= 254 ? [0, 0, 0] : HSVToRGB(c / 256, 1, 1)).map(toHex);

        if (i > 0) {
            st += ",    ";
        }
        st += `${r}, ${g}, ${b}`;
    }
    console.log(`\tdb\t${st}`);
}