function createCode(lang)
{
    return {open: '<pre>', close: '</pre>'};
}

/* TODO:
 * - These should be functions that modify the state. For things like
 *   footnotes, they need to be able to append HTML to the end of the
 *   body.
 * - Aliasing
 * - Macros
 * - Tags: footnote, margin note, table, list, img, url, math-mode
 * - Verbatim tag
 * - Balance brace open/close for unknown tags?
 */
var tags = {
    'b':       {open: '<b>',                    close: '</b>',    },
    'i':       {open: '<i>',                    close: '</i>',    },
    'u':       {open: '<u>',                    close: '</u>',    },
    'm':       {open: '<code>',                 close: '</code>', },
    'tt':      {open: '<tt>',                   close: '</tt>',   },
    'sub':     {open: '<sub>',                  close: '</sub>',  repeat: true},
    'sup':     {open: '<sup>',                  close: '</sup>',  repeat: true},
    'o':       {open: '<span class="o">',       close: '</span>', },
    's':       {open: '<span class="s">',       close: '</span>', },
    'spoiler': {open: '<span class="spoiler">', close: '</span>', },
    'aa':      {open: '<span class="aa">',      close: '</span>', },
    'blink':   {open: '<blink>',                close: '</blink>',},

    //'url':     {open: '<a href="about:blank" rel="nofollow">', close: '</a>', arity: 1}
    //'img':     {open: '<img href="about:blank" rel="nofollow"/>', close: '', arity: 1, verbatim: true}
    'code':    {generator: createCode, arity: 1, block: true},

    'verbatim': {open: '', close: '', verbatim: true}
};


/*
1. Parse t.a.g.s
2. Compute arity
3. Parse to tag close
4. Apply arguments
*/

var r_whitespace = /\s+/;
var r_verbatim = /^[^0-9a-zA-Z\s]+$/;

var r_validTag = /^[a-zA-Z0-9][a-zA-Z0-9\-]*(\*[1-9][0-9]*)?$/;

// Don't want {sub*999999} to crash the browser
var SEXP_MAX_REPEAT = SEXP_MAX_STACK = 96;


function sex()
{
    var input = document.getElementById('in').value;
    var output = parser(input);
    document.getElementById('out').innerHTML = output;
    //document.getElementById('out-dbg').textContent = output;
}


var BRACE_OPEN = '{',
    BRACE_CLOSE = '}',
    BRACE_ESCAPE = '{}\\';


function parser(text)
{
    var ret = '', paragraph = '';
    var stack = [];
    var stackDepth = 0;
    var inVerbatim = false;
    var verbatimOpen = 0;

    for (var i = 0; i < text.length; i++) {
        var c = text[i];

        if (c == '\\') {
            if (BRACE_ESCAPE.indexOf(text[i + 1]) > -1) {
                paragraph += text[i + 1];
                i++;
            }
            else {
                paragraph += c;
            }
        }

        else if (inVerbatim && c == BRACE_OPEN) {
            verbatimOpen += 1;
            paragraph += c;
        }

        else if (inVerbatim && c == BRACE_CLOSE && verbatimOpen > 0) {
            verbatimOpen -= 1;
            paragraph += c;
        }

        else if (c == BRACE_OPEN) {
            var tagbuf = '';
            var ptr = i + 1;

            // Obtain set of tags
            for (; ptr < text.length; ptr++) {
                if (text[ptr].match(r_whitespace) || text[ptr].match(/[\{\}]/))
                    break;

                tagbuf += text[ptr];
            }

            // Special verbatim
            if (tagbuf.match(r_verbatim)) {
                var pos = ptr;

                while (true) {
                    pos = text.indexOf(tagbuf + BRACE_CLOSE, pos);

                    if (pos < 0)
                        break;

                    else if (text[pos - 1].match(r_whitespace)) {
                        paragraph += consideredHarmful(text.substring(ptr + 1, pos - 1));
                        i = pos + 1;
                        break;
                    }

                    pos++;
                }

                if (pos <= 0) {
                    paragraph += c;
                }

                continue;
            }

            // Parse every tag
            var tagbufs = tagbuf.split('.');
            var ok = true;
            var tagStack = [];
            var retTmp = '';

            for (var j = 0; j < tagbufs.length; j++) {
                if (!tagbufs[j].match(r_validTag)) {
                    ok = false;
                    break;
                }

                //var [tag, repeat] = tagbufs[j].split('*');
                var parts = tagbufs[j].split('*');
                var tag = parts[0], repeat = parts[1];

                if (tags[tag] == undefined) {
                    ok = false;
                    break;
                }
                else if (repeat != undefined) {
                    repeat = parseInt(repeat);

                    if (repeat > SEXP_MAX_REPEAT || !tags[tag].repeat) {
                        ok = false;
                        break;
                    }
                }
                else {
                    repeat = 1;
                }

                if (tags[tag].verbatim) {
                    inVerbatim = true;
                }

                while (repeat-- > 0) {
                    tagStack.push(tag);
                    retTmp += tags[tag].open;
                }
            }

            if (!ok || (stackDepth + tagStack.length) > SEXP_MAX_STACK) {
                paragraph += consideredHarmful(c);
                continue;
            }

            i = ptr;
            paragraph += retTmp;
            stack.push(tagStack);
            stackDepth += tagStack.length;
        }

        else if (c == '}' && stack.length) {
            // close tag
            ts = stack.pop();

            for (var j = 0; j < ts.length; j++) {
                if (tags[ts[j]].verbatim)
                    inVerbatim = false;

                paragraph += tags[ts[j]].close;
                stackDepth -= 1;
            }
        }

        else if (text[i] == '\n' && text[i + 1] == '\n') {
            if (paragraph.length) {
                ret += '<p>' + paragraph + '</p>\n';
                paragraph = '';
                i++;
            }
        }

        else {
            paragraph += consideredHarmful(c);
        }
    }

    if (paragraph.length) {
        ret += '<p>' + paragraph + '</p>';
        paragraph = '';
    }

    return ret;
}



function consideredHarmful(text)
{
    return String(text)
        .replace(/&/g, "&#38;")
        .replace(/"/g, '&#34;')
        .replace(/'/g, '&#39;')
        .replace(/</g, '&#60;')
        .replace(/>/g, '&#62;')
        .replace(/\x5C/g, '&#92;')
        .replace(/--/g, '-&#45;');
}

